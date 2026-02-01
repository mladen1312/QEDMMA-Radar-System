#!/usr/bin/env python3
"""
QEDMMA Register Map Generator
[REQ-GEN-REGS-001] SSOT → Multi-target code generation

Generates from YAML SSOT:
1. SystemVerilog package (.sv)
2. C header (.h)
3. Python driver class (.py)
4. Device Tree overlay (.dts)

Author: Dr. Mladen Mešter
Copyright (c) 2026 Dr. Mladen Mešter - All Rights Reserved
"""

import yaml
import argparse
import os
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any

class RegisterMapGenerator:
    """Generate multi-target code from YAML register definitions."""
    
    def __init__(self, yaml_path: str):
        with open(yaml_path, 'r') as f:
            self.config = yaml.safe_load(f)
        
        self.module_name = self.config.get('module', 'unknown')
        self.base_addr = self.config.get('base_address', '0x00000000')
        self.registers = self.config.get('registers', [])
        self.version = self.config.get('version', '1.0.0')
        self.timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    def generate_sv(self) -> str:
        """Generate SystemVerilog package."""
        lines = [
            f"// Auto-generated from YAML SSOT - DO NOT EDIT",
            f"// Module: {self.module_name}",
            f"// Generated: {self.timestamp}",
            f"// Version: {self.version}",
            "",
            f"package {self.module_name}_regs_pkg;",
            "",
            f"  // Base address",
            f"  localparam logic [31:0] {self.module_name.upper()}_BASE = 32'h{self.base_addr[2:]};",
            "",
            f"  // Register offsets",
        ]
        
        for reg in self.registers:
            name = reg['name'].upper()
            offset = reg['offset']
            desc = reg.get('description', '')
            lines.append(f"  localparam logic [15:0] REG_{name} = 16'h{offset[2:]:>04s};  // {desc}")
        
        lines.extend(["", "  // Field definitions"])
        
        for reg in self.registers:
            if 'fields' in reg:
                reg_name = reg['name'].upper()
                lines.append(f"  // {reg_name} fields")
                for field in reg['fields']:
                    fname = field['name'].upper()
                    msb = field['bits'][0]
                    lsb = field['bits'][1] if len(field['bits']) > 1 else field['bits'][0]
                    lines.append(f"  localparam int {reg_name}_{fname}_MSB = {msb};")
                    lines.append(f"  localparam int {reg_name}_{fname}_LSB = {lsb};")
                lines.append("")
        
        lines.extend([
            "",
            f"endpackage : {self.module_name}_regs_pkg",
        ])
        
        return '\n'.join(lines)
    
    def generate_c_header(self) -> str:
        """Generate C header file."""
        guard = f"__{self.module_name.upper()}_REGS_H__"
        
        lines = [
            f"/**",
            f" * Auto-generated from YAML SSOT - DO NOT EDIT",
            f" * Module: {self.module_name}",
            f" * Generated: {self.timestamp}",
            f" * Version: {self.version}",
            f" */",
            "",
            f"#ifndef {guard}",
            f"#define {guard}",
            "",
            f"#include <stdint.h>",
            "",
            f"/* Base address */",
            f"#define {self.module_name.upper()}_BASE  ({self.base_addr}UL)",
            "",
            f"/* Register offsets */",
        ]
        
        for reg in self.registers:
            name = reg['name'].upper()
            offset = reg['offset']
            desc = reg.get('description', '')
            lines.append(f"#define REG_{name}  ({offset}UL)  /* {desc} */")
        
        lines.extend(["", "/* Field masks and shifts */"])
        
        for reg in self.registers:
            if 'fields' in reg:
                reg_name = reg['name'].upper()
                for field in reg['fields']:
                    fname = field['name'].upper()
                    msb = field['bits'][0]
                    lsb = field['bits'][1] if len(field['bits']) > 1 else field['bits'][0]
                    width = msb - lsb + 1
                    mask = ((1 << width) - 1) << lsb
                    lines.append(f"#define {reg_name}_{fname}_SHIFT  ({lsb})")
                    lines.append(f"#define {reg_name}_{fname}_MASK   (0x{mask:08X}UL)")
        
        lines.extend([
            "",
            "/* Register access macros */",
            f"#define {self.module_name.upper()}_READ(offset)  \\",
            f"    (*(volatile uint32_t*)({self.module_name.upper()}_BASE + (offset)))",
            "",
            f"#define {self.module_name.upper()}_WRITE(offset, val)  \\",
            f"    (*(volatile uint32_t*)({self.module_name.upper()}_BASE + (offset)) = (val))",
            "",
            f"#endif /* {guard} */",
        ])
        
        return '\n'.join(lines)
    
    def generate_python(self) -> str:
        """Generate Python driver class."""
        lines = [
            f'"""',
            f'Auto-generated from YAML SSOT - DO NOT EDIT',
            f'Module: {self.module_name}',
            f'Generated: {self.timestamp}',
            f'Version: {self.version}',
            f'"""',
            "",
            "from typing import Optional",
            "import struct",
            "",
            f"class {self.module_name.title().replace('_', '')}Registers:",
            f'    """Register interface for {self.module_name}."""',
            "",
            f"    BASE_ADDRESS = {self.base_addr}",
            "",
            "    # Register offsets",
        ]
        
        for reg in self.registers:
            name = reg['name'].upper()
            offset = reg['offset']
            lines.append(f"    REG_{name} = {offset}")
        
        lines.extend([
            "",
            "    def __init__(self, read_func, write_func):",
            '        """',
            '        Initialize with platform-specific read/write functions.',
            '        ',
            '        Args:',
            '            read_func: Callable(address) -> uint32',
            '            write_func: Callable(address, value) -> None',
            '        """',
            "        self._read = read_func",
            "        self._write = write_func",
            "",
            "    def read(self, offset: int) -> int:",
            '        """Read register at offset."""',
            "        return self._read(self.BASE_ADDRESS + offset)",
            "",
            "    def write(self, offset: int, value: int) -> None:",
            '        """Write register at offset."""',
            "        self._write(self.BASE_ADDRESS + offset, value)",
            "",
        ])
        
        # Generate property getters/setters for each register
        for reg in self.registers:
            name = reg['name'].lower()
            name_upper = reg['name'].upper()
            access = reg.get('access', 'RW')
            desc = reg.get('description', '')
            
            lines.extend([
                "    @property",
                f"    def {name}(self) -> int:",
                f'        """{desc}"""',
                f"        return self.read(self.REG_{name_upper})",
                "",
            ])
            
            if 'W' in access:
                lines.extend([
                    f"    @{name}.setter",
                    f"    def {name}(self, value: int) -> None:",
                    f"        self.write(self.REG_{name_upper}, value)",
                    "",
                ])
        
        return '\n'.join(lines)
    
    def generate_dts(self) -> str:
        """Generate Device Tree Source overlay."""
        lines = [
            f"/* Auto-generated from YAML SSOT - DO NOT EDIT */",
            f"/* Module: {self.module_name} */",
            f"/* Generated: {self.timestamp} */",
            "",
            "/dts-v1/;",
            "/plugin/;",
            "",
            "/ {",
            "    compatible = \"xlnx,zynqmp\";",
            "",
            f"    fragment@0 {{",
            f"        target = <&amba>;",
            f"        __overlay__ {{",
            f"            {self.module_name}: {self.module_name}@{self.base_addr[2:]} {{",
            f'                compatible = "qedmma,{self.module_name}";',
            f"                reg = <0x0 {self.base_addr} 0x0 0x1000>;",
            f"                status = \"okay\";",
        ]
        
        # Add register info as properties
        lines.append(f"                /* Register map */")
        for reg in self.registers:
            name = reg['name'].lower().replace('_', '-')
            offset = reg['offset']
            lines.append(f"                qedmma,reg-{name} = <{offset}>;")
        
        lines.extend([
            f"            }};",
            f"        }};",
            f"    }};",
            "};",
        ])
        
        return '\n'.join(lines)
    
    def generate_all(self, output_dir: str) -> Dict[str, str]:
        """Generate all output files."""
        os.makedirs(output_dir, exist_ok=True)
        
        outputs = {}
        
        # SystemVerilog
        sv_path = os.path.join(output_dir, f"{self.module_name}_regs_pkg.sv")
        with open(sv_path, 'w') as f:
            content = self.generate_sv()
            f.write(content)
            outputs['sv'] = sv_path
        
        # C header
        h_path = os.path.join(output_dir, f"{self.module_name}_regs.h")
        with open(h_path, 'w') as f:
            content = self.generate_c_header()
            f.write(content)
            outputs['c'] = h_path
        
        # Python
        py_path = os.path.join(output_dir, f"{self.module_name}_regs.py")
        with open(py_path, 'w') as f:
            content = self.generate_python()
            f.write(content)
            outputs['py'] = py_path
        
        # Device Tree
        dts_path = os.path.join(output_dir, f"{self.module_name}.dtso")
        with open(dts_path, 'w') as f:
            content = self.generate_dts()
            f.write(content)
            outputs['dts'] = dts_path
        
        return outputs


def main():
    parser = argparse.ArgumentParser(
        description='Generate code from YAML register map SSOT'
    )
    parser.add_argument(
        '--input', '-i',
        required=True,
        help='Input YAML file path (or glob pattern)'
    )
    parser.add_argument(
        '--output', '-o',
        default='./generated',
        help='Output directory'
    )
    parser.add_argument(
        '--format', '-f',
        choices=['all', 'sv', 'c', 'py', 'dts'],
        default='all',
        help='Output format(s)'
    )
    
    args = parser.parse_args()
    
    # Handle glob patterns
    input_files = list(Path('.').glob(args.input)) if '*' in args.input else [Path(args.input)]
    
    for yaml_path in input_files:
        print(f"Processing: {yaml_path}")
        
        gen = RegisterMapGenerator(str(yaml_path))
        outputs = gen.generate_all(args.output)
        
        for fmt, path in outputs.items():
            print(f"  ✅ Generated: {path}")
    
    print(f"\n✅ All outputs generated in: {args.output}")


if __name__ == "__main__":
    main()
