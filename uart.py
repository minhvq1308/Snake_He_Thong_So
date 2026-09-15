import serial
from pynput import keyboard

# Thay 'COM7' bằng đúng cổng COM của Tang Nano 20K trên máy bạn
COM_PORT = 'COM7'
BAUD_RATE = 115200

try:
    ser = serial.Serial(COM_PORT, BAUD_RATE, timeout=1)
    print(f"--- Đã kết nối thành công tới {COM_PORT}! ---")
except Exception as e:
    print(f"Lỗi kết nối: {e}")
    print("Hãy đảm bảo đã đóng Arduino IDE / Hercules trước khi chạy!")
    exit()

def on_press(key):
    try:
        # Nhận diện trực tiếp phím A, W, S, D
        if hasattr(key, 'char') and key.char is not None:
            char = key.char.lower()
            if char in ['w', 'a', 's', 'd']:
                ser.write(char.encode())
                print(f"Nhấn: {char.upper()} -> Đã gửi byte '{char}' qua UART")
    except Exception as e:
        print(f"Lỗi gửi dữ liệu: {e}")

print("Đã bật nhận diện phím A, W, S, D. Nhấn trực tiếp phím trên bàn phím laptop!")
print("Bấm Ctrl + C trong cửa sổ Terminal để dừng chương trình.\n")

with keyboard.Listener(on_press=on_press) as listener:
    listener.join()