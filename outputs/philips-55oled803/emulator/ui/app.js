const $ = id => document.getElementById(id);
let token = "", fixture = "framebuffer", state = null, polling = false;
let framePixels = null, frameWords = null, lastFrameAt = 0, viewFrames = 0, viewRate = 0, rateStart = performance.now();
let actionPending = false;
const notice = text => { $("notice").textContent = text; $("notice").classList.toggle("hidden", !text); };
async function action(path, body = {}) {
  if (!token) throw new Error("Control session is not ready.");
  const response = await fetch(path, {method:"POST", headers:{
    "Content-Type":"application/json", "X-TVUI-Token":token}, body:JSON.stringify(body)});
  const result = await response.json();
  if (!response.ok) throw new Error(result.error || "Action failed");
  return result;
}
function lights(pixels) {
  // Inspection arrangement only; sequence remains SPI wire order.
  const count = pixels.length || 28;
  const left = Math.floor(count / 4), top = count - left * 2;
  const groups = [["lights-left",0,left],["lights-top",left,left+top],
    ["lights-right",left+top,count]];
  for (const [id,start,end] of groups) {
    const host = $(id);
    host.replaceChildren();
    for (let i=start;i<end;i++) {
      const led = document.createElement("i");
      led.className = "light";
      if (pixels[i]) {
        const color = pixels[i].map(v=>Math.max(0,Math.min(255,Number(v)||0)));
        led.style.setProperty("--color",`rgb(${color.join(",")})`);
        led.classList.add("active");
        led.title = `SPI pixel ${i+1}: RGB ${color.join(", ")}`;
      } else led.title = "No captured SPI value";
      host.append(led);
    }
  }
}
function render(s) {
  state = s;
  $("connection").textContent = "● Local connection";
  $("start").disabled = s.running || actionPending;
  $("stop").disabled = !s.running || actionPending;
  $("power-led").classList.toggle("on",s.running);
  $("process-status").textContent = s.running ? "Running" : s.exit_code !== null ? "Stopped" : "Ready";
  $("process-detail").textContent = s.running ? `${Math.floor(s.uptime/60)}m ${s.uptime%60}s · process ${s.pid}` :
    s.exit_code !== null ? `QEMU exit status ${s.exit_code}` : "Local, isolated process";
  $("boot-status").textContent = {complete:"Complete",not_complete:"Starting",unknown:"Unknown"}[s.boot];
  $("boot-detail").textContent = s.boot === "complete" ? "Guest sys.boot_completed = 1" :
    s.boot === "not_complete" ? "Guest has not reported completion" : "No guest status response yet";
  $("spi-status").textContent = s.pixels.length ? `${s.pixels.length} wire pixels` : "No transfers";
  $("spi-detail").textContent = s.pixels.length ? `Guest SPI transfer ${s.spi_sequence}` : "Waiting for guest output";
  const bridge = s.input_bridge || {status:"idle",pending:0,capacity:4};
  const remoteReady = s.input_ready && bridge.status === "ready";
  $("remote-state").textContent = !s.console_connected ? "OFFLINE" :
    !s.input_ready ? "WAITING FOR ANDROID" : ({ready:"READY",preparing:"PREPARING REMOTE",
      failed:"REMOTE UNAVAILABLE",uncertain:"WAITING FOR ACK"}[bridge.status] || "WAITING FOR BRIDGE");
  document.querySelectorAll("[data-key]").forEach(b=>b.disabled=!remoteReady || bridge.pending >= bridge.capacity);
  $("check-boot").disabled = !s.console_connected;
  if (s.commands.length) {
    const cmd = s.commands[s.commands.length-1];
    const names = {queued:"Queued behind the current key…",pending:"Waiting for guest acknowledgement…",
      accepted:"Guest input dispatcher accepted the key.",accepted_late:"Guest acknowledgement arrived late.",
      failed:`Key failed${cmd.error ? `: ${cmd.error}` : "."}`,
      cancelled:"Not sent because the previous key has an uncertain outcome.",
      timeout:"No acknowledgement; outcome unknown. The key was not retried."};
    const timing = cmd.host_ms !== undefined ? ` · ${cmd.host_ms} ms to ACK${cmd.guest_ms !== null ? ` · ${cmd.guest_ms} ms in guest` : ""}` : "";
    $("key-feedback").textContent = `${cmd.key.replaceAll("_"," ")} · ${names[cmd.status] || cmd.status}${timing}`;
  } else $("key-feedback").textContent = remoteReady ?
    "Persistent Android input is ready. Acknowledgements report dispatch, not screen changes." :
    bridge.error ? `Remote: ${bridge.error}` : bridge.status === "preparing" ?
    "Preparing one persistent input process in the Android shell." :
    "Remote buttons become available when Android input and the persistent bridge are ready.";
  $("frame").classList.toggle("hidden", !lastFrameAt);
  $("frame-empty").classList.toggle("hidden", !!lastFrameAt);
  $("image-status").textContent = s.frame ? "ACTUAL QEMU FRAMEBUFFER" : "WAITING FOR QEMU";
  $("frame-age").textContent = lastFrameAt ? `${viewRate.toFixed(1)} VIEW FPS · ${Math.max(0,Math.round(performance.now()-lastFrameAt))}ms SINCE DISPLAY` : "NO FRAME YET";
  $("image-note").textContent = s.frame ? s.scanout_observed ?
    "Raw guest OSD input. A captured frame does not imply Android boot has completed." :
    "QEMU capture available. Guest OSD scanout has not been observed; the display may be uninitialized." :
    "The framebuffer will appear here, including black or uninitialized frames.";
  $("fixture-note").textContent = s.running ? `Active: ${s.fixture}. Selected: ${fixture}. Stop and start to apply a change.` :
    `${fixture[0].toUpperCase()+fixture.slice(1)} measurement fixture applies on the next start.`;
  const activeInput = s.running ? s.fixture : fixture;
  $("input-kind").textContent = activeInput === "framebuffer" ? "FRAMEBUFFER" : "FIXTURE";
  $("input-description").textContent = activeInput === "framebuffer" ?
    "Experimental guest-framebuffer measurements. Lights still show captured guest SPI output; physical layout is uncalibrated." :
    "Synthetic measurement color. The lights show the guest driver’s resulting SPI values.";
  $("console-log").textContent = s.console_log || "No console output yet.";
  $("qemu-log").textContent = s.qemu_log || "No boot output yet.";
  $("run-path").textContent = s.run_directory || "";
  lights(s.pixels);
  if (s.error) notice(s.error);
}
async function refresh() {
  if (polling) return;
  polling = true;
  try {
    const response = await fetch("/api/state");
    if (!response.ok) throw new Error("Local server unavailable");
    render(await response.json());
  } catch(e) { $("connection").textContent="Disconnected"; notice(e.message); }
  finally { polling=false; }
}
async function control(fn) {
  try { notice(""); actionPending=true; if(state) render(state); await fn(); }
  catch(e) { notice(e.message); }
  finally { actionPending=false; await refresh(); }
}
$("start").onclick = ()=>control(()=>action("/api/start",{fixture}));
$("stop").onclick = ()=>control(()=>action("/api/stop"));
$("refresh").onclick = ()=>refresh();
$("check-boot").onclick = ()=>control(()=>action("/api/check-boot"));
document.querySelectorAll("[data-key]").forEach(b=>{
  b.disabled = true;
  b.onclick = ()=>control(()=>action("/api/key",{key:b.dataset.key}));
});
document.querySelectorAll("[data-color]").forEach(b=>b.onclick=()=>{
  fixture=b.dataset.color;
  document.querySelectorAll("[data-color]").forEach(x=>x.classList.toggle("selected",x===b));
  if(state) render(state);
});
// Fetch only after the previous frame is displayed. This bounds latency and
// memory even if rendering or the browser slows down; no queued frame backlog.
async function frameLoop() {
  const started = performance.now();
  try {
    if (!document.hidden && state?.frame) {
      const response = await fetch("/frame.ppm");
      if (response.ok) {
        const bytes = new Uint8Array(await response.arrayBuffer());
        const header = new TextDecoder().decode(bytes.subarray(0,80)).match(/^P6\n(\d+) (\d+)\n255\n/);
        if (!header) throw new Error("Invalid framebuffer header");
        const width = Number(header[1]), height = Number(header[2]), offset = header[0].length;
        if (width < 1 || height < 1 || width > 4096 || height > 2160 || bytes.length !== offset + width*height*3)
          throw new Error("Invalid framebuffer dimensions");
        const canvas = $("frame");
        if (!framePixels || canvas.width !== width || canvas.height !== height) {
          canvas.width = width; canvas.height = height;
          framePixels = new ImageData(width,height);
          frameWords = new Uint32Array(framePixels.data.buffer);
        }
        // Supported desktop hosts are little-endian; ImageData is RGBA bytes.
        for (let i=0,p=offset;i<frameWords.length;i++,p+=3)
          frameWords[i] = 0xff000000 | bytes[p] | bytes[p+1]<<8 | bytes[p+2]<<16;
        canvas.getContext("2d",{alpha:false}).putImageData(framePixels,0,0);
        lastFrameAt = performance.now();
        canvas.classList.remove("hidden"); $("frame-empty").classList.add("hidden");
        viewFrames++;
        if (lastFrameAt-rateStart >= 1000) {
          viewRate = viewFrames*1000/(lastFrameAt-rateStart); viewFrames=0; rateStart=lastFrameAt;
        }
      }
    }
  } catch(e) { notice(`Display: ${e.message}`); }
  setTimeout(frameLoop,Math.max(5,50-(performance.now()-started)));
}
async function init() {
  try { token=(await (await fetch("/api/session")).json()).token; await refresh(); }
  catch(e) { notice(e.message); }
  setInterval(refresh,250);
  frameLoop();
}
lights([]);
init();
