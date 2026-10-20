package tv.emulator;
import java.io.*;
import java.util.*;

public final class ProtocolTest {
    private static final List<Integer> taps = new ArrayList<Integer>();
    private static String run(String requests, final int behavior) throws Exception {
        taps.clear();
        StringWriter output = new StringWriter();
        BridgeProtocol.run(new ByteArrayInputStream(requests.getBytes("UTF-8")), new PrintWriter(output),
            new BridgeProtocol.Injector() {
                public boolean tap(int key) throws Exception {
                    taps.add(key);
                    if (behavior == 2) throw new IOException("test");
                    return behavior == 0;
                }
            }, new BridgeProtocol.Clock() {
                private long time;
                public long millis() { time += 3; return time; }
            });
        return output.toString();
    }
    private static void require(boolean pass, String label) {
        if (!pass) throw new AssertionError(label);
    }
    public static void main(String[] args) throws Exception {
        String result = run("PING 1\nKEY 2 19\r\nQUIT 3\nKEY 4 20\n", 0);
        require(result.equals("READY PHILIPS_INPUT_V1\nACK 1 PONG\nACK 2 KEY 3\nACK 3 BYE\n"), "normal protocol and CRLF");
        require(taps.equals(Arrays.asList(19)), "QUIT stops dispatch");
        result = run("KEY 2 26\nKEY 3 19;reboot\nKEY 4 20 extra\nKEY -1 19\nKEY 2147483648 19\nKEY 0 19\nKEY 5 20\n", 0);
        require(taps.equals(Arrays.asList(20)), "deny arbitrary input and disallowed power");
        require(result.contains("ERR 2 KEY_NOT_ALLOWED") && result.contains("ACK 5 KEY 3"), "error recovery");
        char[] huge = new char[1000000]; Arrays.fill(huge, 'x');
        result = run(new String(huge) + "\nKEY 8 23\n", 0);
        require(result.contains("ERR 0 BAD_LINE") && taps.equals(Arrays.asList(23)), "bounded overlong line recovery");
        result = run("KEY 1 19\u0000\nKEY 2 20\rX\nKEY 3 21é\nKEY 4 22", 0);
        require(taps.isEmpty() && result.endsWith("ERR 0 TRUNCATED\n"), "control, non-ASCII and partial lines denied");
        require(run("KEY 1 19\n", 1).contains("ERR 1 INJECT_REJECTED 3"), "false injection acknowledgement");
        require(run("KEY 1 19\n", 2).contains("ERR 1 INJECT_EXCEPTION 3"), "exception acknowledgement");
        int count = 0;
        for (int key = 0; key < 400; key++) if (BridgeProtocol.allowed(key)) count++;
        require(count == 28, "allowlist size");
        System.out.println("PASS: bounded protocol, allowlist, IDs, framing, EOF, acknowledgements and injection failures");
    }
}
