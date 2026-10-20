package tv.emulator;

import android.os.SystemClock;
import android.view.InputDevice;
import android.view.InputEvent;
import android.view.KeyCharacterMap;
import android.view.KeyEvent;
import java.io.PrintWriter;
import java.io.BufferedInputStream;
import java.lang.reflect.Method;

/** Run once under the ordinary Android shell UID and SELinux domain. */
public final class InputBridge {
    private static final class AndroidInjector implements BridgeProtocol.Injector {
        private final Object manager;
        private final Method inject;
        private final int waitForFinish;
        AndroidInjector() throws Exception {
            Class<?> type = Class.forName("android.hardware.input.InputManager");
            manager = type.getMethod("getInstance").invoke(null);
            inject = type.getMethod("injectInputEvent", InputEvent.class, int.class);
            waitForFinish = type.getField("INJECT_INPUT_EVENT_MODE_WAIT_FOR_FINISH").getInt(null);
        }
        private boolean send(long downTime, int action, int code) throws Exception {
            KeyEvent event = new KeyEvent(downTime, SystemClock.uptimeMillis(), action,
                code, 0, 0, KeyCharacterMap.VIRTUAL_KEYBOARD, 0, 0, InputDevice.SOURCE_KEYBOARD);
            return Boolean.TRUE.equals(inject.invoke(manager, event, waitForFinish));
        }
        public boolean tap(int code) throws Exception {
            long downTime = SystemClock.uptimeMillis();
            boolean down = false, up;
            try { down = send(downTime, KeyEvent.ACTION_DOWN, code); }
            finally { up = send(downTime, KeyEvent.ACTION_UP, code); }
            return down && up;
        }
    }
    public static void main(String[] args) {
        PrintWriter out = new PrintWriter(System.out, true);
        if (args.length != 0) { out.println("FATAL ARGUMENTS"); return; }
        if (android.os.Process.myUid() != 2000) { out.println("FATAL SHELL_UID_REQUIRED"); return; }
        try {
            BridgeProtocol.run(new BufferedInputStream(System.in, 1024), out, new AndroidInjector(), new BridgeProtocol.Clock() {
                public long millis() { return SystemClock.uptimeMillis(); }
            });
        } catch (Exception e) {
            out.println("FATAL " + e.getClass().getSimpleName());
        }
    }
}
