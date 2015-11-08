{
  Pascal/Delphi bindings for the UnicornEngine Emulator Engine

  Copyright(c) 2015 Stefan Ascher

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  version 2 as published by the Free Software Foundation.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
}

program SampleArm64;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$ifdef MSWINDOWS}
	{$apptype CONSOLE}
	{$R *.res}
{$endif}

uses
	SysUtils, Unicorn, UnicornConst, Arm64Const;

const
	// code to be emulated WITH terminating 0
	ARM_CODE: array[0..4] of Byte = ($ab, $01, $0f, $8b, $00);
	// memory address where emulation starts
	ADDRESS = $10000;

procedure HookBlock(uc: uc_engine; address: UInt64; size: Cardinal; user_data: Pointer); cdecl;
begin
  WriteLn(Format('>>> Tracing basic block at 0x%x, block size = 0x%x', [address, size]));
end;

procedure HookCode(uc: uc_engine; address: UInt64; size: Cardinal; user_data: Pointer); cdecl;
begin
  WriteLn(Format('>>> Tracing instruction at 0x%, instruction size = 0x%x', [address, size]));
end;

procedure TestArm64;
var
	uc: uc_engine;
  err: uc_err;
  trace1, trace2: uc_hook;
  x11, x13, x15: Int64;
begin
	x11 := $1234;      // X11 register
	x13 := $6789;      // X13 register
	x15 := $3333;      // X14 register

  WriteLn('Emulate ARM64 code');

  // Initialize emulator in ARM mode
  err := uc_open(UC_ARCH_ARM64, UC_MODE_ARM, &uc);
  if (err <> UC_ERR_OK) then begin
    WriteLn(Format('Failed on uc_open() with error returned: %u (%s)', [err, uc_strerror(err)]));
    Halt(1);
  end;

  // map 2MB memory for this emulation
  uc_mem_map(uc, ADDRESS, 2 * 1024 * 1024, UC_PROT_ALL);

  // write machine code to be emulated to memory
  uc_mem_write_(uc, ADDRESS, @ARM_CODE, SizeOf(ARM_CODE) - 1);

  // initialize machine registers
  uc_reg_write(uc, UC_ARM64_REG_X11, @x11);
  uc_reg_write(uc, UC_ARM64_REG_X13, @x13);
  uc_reg_write(uc, UC_ARM64_REG_X15, @x15);

  // tracing all basic blocks with customized callback
  uc_hook_add_2(uc, trace1, UC_HOOK_BLOCK, @HookBlock, nil, 1, 0);

  // tracing one instruction at ADDRESS with customized callback
  uc_hook_add_2(uc, trace2, UC_HOOK_CODE, @HookCode, nil, ADDRESS, ADDRESS);

  // emulate machine code in infinite time (last param = 0), or when
  // finishing all the code.
	err := uc_emu_start(uc, ADDRESS, ADDRESS + SizeOf(ARM_CODE) - 1, 0, 0);
  if (err <> UC_ERR_OK) then begin
  	WriteLn(Format('Failed on uc_emu_start() with error returned: %u', [err]));
  end;

	// now print out some registers
  WriteLn('>>> Emulation done. Below is the CPU context');
  uc_reg_read(uc, UC_ARM64_REG_X11, @x11);
  WriteLn(Format('>>> X11 = 0x%x', [x11]));

  uc_close(uc);
end;

begin
	TestArm64;
end.
