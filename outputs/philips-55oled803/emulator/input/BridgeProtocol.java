package tv.emulator;

import java.io.InputStream;
import java.io.IOException;
import java.io.PrintWriter;

/** Bounded ASCII protocol; no command execution, paths, networking or dynamic code. */
public final class BridgeProtocol {
    public static final int MAX_LINE = 64;
    public interface Injector { boolean tap(int keyCode) throws Exception; }
    public interface Clock { long millis(); }
    public static boolean allowed(int code) {
        switch (code) {
            case 3: case 4: // Home, Back
            case 19: case 20: case 21: case 22: case 23: // D-pad
            case 24: case 25: case 82: // Volume, Menu
            case 85: case 86: case 87: case 88: case 89: case 90: // Media
            case 126: case 127: case 164: // Play, Pause, Mute
            case 165: case 166: case 167: case 172: case 178: // TV
            case 183: case 184: case 185: case 186: // Color buttons
                return true;
            default: return false;
        }
    }
    private static int positive(String text) {
        if (text.isEmpty() || text.length() > 10) return -1;
        long value = 0;
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            if (c < '0' || c > '9') return -1;
            value = value * 10 + c - '0';
            if (value > Integer.MAX_VALUE) return -1;
        }
        return value == 0 ? -1 : (int)value;
    }
    private static boolean dispatch(String line, PrintWriter out, Injector injector, Clock clock) {
        String[] words = line.split(" ", -1);
        int id = words.length >= 2 ? positive(words[1]) : -1;
        if (id < 0) { out.println("ERR 0 BAD_REQUEST"); return true; }
        if (words.length == 2 && words[0].equals("PING")) {
            out.println("ACK " + id + " PONG"); return true;
        }
        if (words.length == 2 && words[0].equals("QUIT")) {
            out.println("ACK " + id + " BYE"); return false;
        }
        if (words.length != 3 || !words[0].equals("KEY")) {
            out.println("ERR " + id + " BAD_REQUEST"); return true;
        }
        int code = positive(words[2]);
        if (!allowed(code)) { out.println("ERR " + id + " KEY_NOT_ALLOWED"); return true; }
        long start = clock.millis();
        String status;
        try { status = injector.tap(code) ? "ACK " + id + " KEY" : "ERR " + id + " INJECT_REJECTED"; }
        catch (Exception e) { status = "ERR " + id + " INJECT_EXCEPTION"; }
        out.println(status + " " + Math.max(0, clock.millis() - start));
        return true;
    }
    public static void run(InputStream in, PrintWriter out, Injector injector, Clock clock) throws IOException {
        byte[] buffer = new byte[MAX_LINE];
        int count = 0;
        boolean invalid = false, sawCR = false;
        out.println("READY PHILIPS_INPUT_V1");
        out.flush();
        int value;
        while ((value = in.read()) != -1) {
            if (value == '\n') {
                boolean again;
                if (invalid) { out.println("ERR 0 BAD_LINE"); again = true; }
                else { again = dispatch(new String(buffer, 0, count, "US-ASCII"), out, injector, clock); }
                out.flush();
                if (!again || out.checkError()) return;
                count = 0; invalid = false; sawCR = false;
            } else if (value == '\r' && !sawCR) {
                sawCR = true;
            } else if (sawCR || value < 32 || value > 126 || count == MAX_LINE) {
                invalid = true; // Drain to newline with bounded memory.
            } else if (!invalid) {
                buffer[count++] = (byte)value;
            }
        }
        // A partial request is never executed after EOF.
        if (count != 0 || invalid || sawCR) { out.println("ERR 0 TRUNCATED"); out.flush(); }
    }
}
