const $ = id => document.getElementById(id);
let token = "", fixture = "framebuffer", state = null, lastFrame = null, polling = false;
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
  $("remote-state").textContent = s.input_ready ? "READY" : s.console_connected ? "WAITING FOR ANDROID" : "OFFLINE";
  document.querySelectorAll("[data-key]").forEach(b=>b.disabled=!s.input_ready);
  $("check-boot").disabled = !s.console_connected;
  if (s.commands.length) {
    const cmd = s.commands[s.commands.length-1];
    const names = {pending:"Waiting for guest acknowledgment…",
      accepted:"Guest accepted the key command. Screen response is not verified.",
      failed:`Guest command failed${cmd.exit_code !== undefined ? ` (exit ${cmd.exit_code})` : ""}.`,
      timeout:"No guest acknowledgment. The shell or Android input service may not be ready."};
    $("key-feedback").textContent = `${cmd.key.replaceAll("_"," ")} · ${names[cmd.status] || cmd.status}`;
  } else $("key-feedback").textContent = s.input_ready ?
    "Keys are sent to Android. Each command waits for a guest acknowledgment." :
    "Remote buttons become available when Android's input service is ready.";
  if (s.frame && lastFrame !== s.frame_time) {
    $("frame").src = `/frame.png?t=${s.frame_time}`;
    lastFrame = s.frame_time;
  }
  $("frame").classList.toggle("hidden", !s.frame);
  $("frame-empty").classList.toggle("hidden", s.frame);
  $("image-status").textContent = s.frame ? "ACTUAL QEMU FRAMEBUFFER" : "WAITING FOR QEMU";
  $("frame-age").textContent = s.frame_time ? `${Math.max(0,Math.floor(Date.now()/1000-s.frame_time))}s SINCE CAPTURE` : "NO FRAME YET";
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
$("frame").onerror = ()=>notice("The latest framebuffer image could not be loaded.");
async function init() {
  try { token=(await (await fetch("/api/session")).json()).token; await refresh(); }
  catch(e) { notice(e.message); }
  setInterval(refresh,1500);
}
lights([]);
init();
