# -*- coding: utf-8 -*-
"""Dart 源码基础体检：括号平衡 + 低级错误模式扫描（无 Flutter SDK 时的替代检查）。"""
import re
from pathlib import Path

ok = True
for f in sorted(Path('lib').rglob('*.dart')):
    src = f.read_text(encoding='utf-8')
    # 去掉注释与字符串字面量后再数括号
    s = re.sub(r'//.*', '', src)
    s = re.sub(r'/\*.*?\*/', '', s, flags=re.S)
    s = re.sub(r"'(\\.|[^'\\])*'", "''", s)
    s = re.sub(r'"(\\.|[^"\\])*"', '""', s)
    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    line = 1
    for ch in s:
        if ch == '\n':
            line += 1
        if ch in '([{':
            stack.append((ch, line))
        elif ch in ')]}':
            if not stack or stack[-1][0] != pairs[ch]:
                print(f'{f}: 括号不匹配 {ch} @行{line}')
                ok = False
                break
            stack.pop()
    if stack:
        print(f'{f}: 未闭合 {stack[-1]}')
        ok = False
    for pat, msg in [
        (r'\?\?\s*""', '空字符串回退'),
        (r"\.get\('ar'\)", '硬编码 ar 语言'),
        (r'\.clamp\(', 'clamp 用法'),
    ]:
        for m in re.finditer(pat, src):
            ctx = src[max(0, m.start() - 50):m.end() + 20].splitlines()[-1][:100]
            print(f'{f}: [{msg}] {ctx}')
print('BALANCE OK' if ok else 'BALANCE FAIL')
