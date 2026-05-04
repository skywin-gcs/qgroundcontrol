#!/usr/bin/env python3
"""Simple test for VideoProcessor"""
import subprocess
import sys
import time

# Start the VideoProcessor
proc = subprocess.Popen(
    ['/opt/homebrew/bin/python3', 'src/VideoManager/VideoReceiver/VideoProcessor.py'],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    env={'KMP_DUPLICATE_LIB_OK': 'TRUE'}
)

# Send a small test frame (fake JPEG)
test_data = b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xff\xdb\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\x0c\x14\r\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d\x1a\x1f\x1e\x1d\x1a\x1c\x1c $.\' ",#\x1c\x1c(7),01444\x1f\'9=82<.342\xff\xc0\x00\x11\x08\x00\x01\x00\x01\x01\x01\x11\x00\x02\x11\x01\x03\x11\x01\xff\xc4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xff\xc4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xda\x00\x0c\x03\x01\x00\x02\x11\x03\x11\x00\x3f\x00\xaa\xff\xd9'

# Send frame size (4 bytes little-endian) + frame data
import struct
size_bytes = struct.pack('<I', len(test_data))
proc.stdin.write(size_bytes)
proc.stdin.write(test_data)
proc.stdin.close()

# Read output with timeout
try:
    stdout, stderr = proc.communicate(timeout=5)
    print("=== STDOUT ===")
    print(stdout.decode() if stdout else "(no output)")
    print("=== STDERR ===")
    print(stderr.decode() if stderr else "(no errors)")
    print(f"=== Return Code: {proc.returncode} ===")
except subprocess.TimeoutExpired:
    proc.kill()
    stdout, stderr = proc.communicate()
    print("Process timed out")
    print("=== STDERR ===")
    print(stderr.decode() if stderr else "(no errors)")
