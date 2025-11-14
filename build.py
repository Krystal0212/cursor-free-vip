import os
import platform
import shutil
import threading
import time
import warnings
from dotenv import load_dotenv
from logo import print_logo

# Ignore noisy PyInstaller warnings
warnings.filterwarnings("ignore", category=SyntaxWarning)


class LoadingAnimation:
    def __init__(self) -> None:
        self._running = False
        self._thread = None

    def start(self, message: str = "Building") -> None:
        self._running = True
        self._thread = threading.Thread(target=self._animate, args=(message,), daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._running = False
        if self._thread:
            self._thread.join()
        print("\r" + " " * 80 + "\r", end="", flush=True)

    def _animate(self, message: str) -> None:
        spinner = "|/-\\"
        idx = 0
        while self._running:
            print(f"\r{message} {spinner[idx % len(spinner)]}", end="", flush=True)
            idx += 1
            time.sleep(0.1)


def progress_bar(progress: int, total: int, prefix: str = "", length: int = 40) -> None:
    filled = int(length * progress // total)
    bar = "#" * filled + "-" * (length - filled)
    percent = (100 * progress / total) if total else 0
    print(f"\r{prefix} |{bar}| {percent:5.1f}%", end="", flush=True)
    if progress == total:
        print()


def simulate_step(message: str, duration: float = 0.5, steps: int = 20) -> None:
    print(f"\033[94m{message}\033[0m")
    for i in range(steps + 1):
        time.sleep(duration / steps)
        progress_bar(i, steps, prefix="Progress:")


def resolve_output_name(system: str, base_name: str) -> tuple[str, str]:
    if system == "windows":
        return base_name, ".exe"
    suffix = "linux" if system == "linux" else "mac"
    return f"{base_name}_{suffix}", ""


def build() -> bool:
    os.system("cls" if platform.system().lower() == "windows" else "clear")
    print_logo()

    print("\033[93m[•] Cleaning build cache...\033[0m")
    if os.path.isdir("build"):
        shutil.rmtree("build")

    load_dotenv(override=True)
    version = os.getenv("VERSION", "1.0.0")
    output_name_base = os.getenv("OUTPUT_NAME", "CursorVipActivator")
    print(f"\033[93m[•] Building version v{version} -> {output_name_base}\033[0m")

    simulate_step("Preparing build environment...")

    system = platform.system().lower()
    output_name, ext = resolve_output_name(system, output_name_base)
    output_path = os.path.join("dist", f"{output_name}{ext}")

    loader = LoadingAnimation()
    loader.start("Building in progress")
    try:
        os.system("pyinstaller --clean --noconfirm build.spec")
    finally:
        loader.stop()

    if os.path.exists(output_path):
        print(f"\n\033[92m[✓] Build completed!\033[0m")
        print(f"\033[92m[✓] Executable file located: {output_path}\033[0m")
        return True

    print("\n\033[91m[✗] Build failed: Output file not found\033[0m")
    return False


if __name__ == "__main__":
    build()
