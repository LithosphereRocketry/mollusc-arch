;         lui sp, 0x800           ; initialize stack

;         lui s2, 0x01000000 ; address of IO segment
;         ldpi a0, s2, 8          ; need to wait for here for some reason, otherwise USB CDC fails

;         lui a0, msg_start
;         addi a0, a0, msg_start
;         j ra, puts

; ; >>> SDRAM init sequence based on liblitedram sdram_init() in sdram.c

; ; Init structure memory layout:
; ; 0: int read_dq_delay[2]
; ; 8: int read_dq_bitslip[2]

;         ; printf("Initializing SDRAM @0x%08lx...\n", MAIN_RAM_BASE);
;         lui a0, msg_dram_init
;         addi a0, a0, msg_dram_init
;         j ra, puts
;         lui a0, 0xF8000000
;         j ra, putx
;         lui a0, msg_dram_init_after
;         addi a0, a0, msg_dram_init_after
;         j ra, puts

;         ; sdram_software_control_on();
;         j ra, software_control_on

;         lui s2, 0x10000 ; s2 = CSR_BASE
;         lui s3, 0x11000 ; s3 = CSR_BASE + 0x1000

;         ; ddrctrl_init_done_write(0);
;                 ; csr_write_simple(v, (CSR_BASE + 0x0L));
;         stpi zero, s2, 0
;         ; ddrctrl_init_error_write(0);
;                 ; csr_write_simple(v, (CSR_BASE + 0x4L));
;         stpi zero, s2, 4
;         ; init_sequence();
;         	; /* Release reset */
;                 ; sdram_dfii_pi0_address_write(0x0);
;                         ; csr_write_simple(v, (CSR_BASE + 0x100cL));
;         stpi zero, s3, 0xc
;                 ; sdram_dfii_pi0_baddress_write(0);
;                         ; csr_write_simple(v, (CSR_BASE + 0x1010L));
;         stpi zero, s3, 0x10
;                 ; sdram_dfii_control_write(DFII_CONTROL_ODT|DFII_CONTROL_RESET_N);
;                         ; csr_write_simple(v, (CSR_BASE + 0x1000L));
;         addi a1, zero, 0b1100
;         stpi a1, s3, 0
;                 ; cdelay(50000);
;         lui a0, 0xC000
;         addi a0, a0, 0x350
;         j ra, cdelay

;                 ; /* Bring CKE high */
;                 ; sdram_dfii_pi0_address_write(0x0);
;                         ; csr_write_simple(v, (CSR_BASE + 0x100cL));
;         stpi zero, s3, 0xc
;                 ; sdram_dfii_pi0_baddress_write(0);
;                         ; csr_write_simple(v, (CSR_BASE + 0x1010L));
;         stpi zero, s3, 0x10
;                 ; sdram_dfii_control_write(DFII_CONTROL_CKE|DFII_CONTROL_ODT|DFII_CONTROL_RESET_N);
;                         ; csr_write_simple(v, (CSR_BASE + 0x1000L));
;         addi a1, zero, 0b1110
;         stpi a1, s3, 0
;                 ; cdelay(10000);
;         lui a0, 0x2000
;         addi a0, a0, 0x710
;         j ra, cdelay

;                 ; /* Load Mode Register 2, CWL=5 */
;                 ; sdram_dfii_pi0_address_write(0x200);
;                         ; csr_write_simple(v, (CSR_BASE + 0x100cL));
;         addi a1, zero, 0x200
;         stpi a1, s3, 0xc
;                 ; sdram_dfii_pi0_baddress_write(2);
;                         ; csr_write_simple(v, (CSR_BASE + 0x1010L));
;         addi a1, zero, 2
;         stpi a1, s3, 0x10
; 	        ; command_p0(DFII_COMMAND_RAS|DFII_COMMAND_CAS|DFII_COMMAND_WE|DFII_COMMAND_CS);
;                         ; sdram_dfii_pi0_command_write(cmd);
;                                 ; csr_write_simple(v, (CSR_BASE + 0x1004L));
;         addi a1, zero, 0b1111
;         stpi a1, s3, 0x4
;                         ; sdram_dfii_pi0_command_issue_write(1);
;                                 ; csr_write_simple(v, (CSR_BASE + 0x1008L));
;         addi a1, zero, 1
;         stpi a1, s3, 0x8

;                 ; /* Load Mode Register 3 */
;                 ; sdram_dfii_pi0_address_write(0x0);
;                         ; csr_write_simple(v, (CSR_BASE + 0x100cL));
;         stpi zero, s3, 0xc
;                 ; sdram_dfii_pi0_baddress_write(3);
;                         ; csr_write_simple(v, (CSR_BASE + 0x1010L));
;         addi a1, zero, 3
;         stpi a1, s3, 0x10
;                 ; command_p0(DFII_COMMAND_RAS|DFII_COMMAND_CAS|DFII_COMMAND_WE|DFII_COMMAND_CS);
;                         ; sdram_dfii_pi0_command_write(cmd);
;                                 ; csr_write_simple(v, (CSR_BASE + 0x1004L));
;         addi a1, zero, 0b1111
;         stpi a1, s3, 0x4
;                         ; sdram_dfii_pi0_command_issue_write(1);
;                                 ; csr_write_simple(v, (CSR_BASE + 0x1008L));
;         addi a1, zero, 1
;         stpi a1, s3, 0x8

;                 ; /* Load Mode Register 1 */
;                 ; sdram_dfii_pi0_address_write(0x6);
;                         ; csr_write_simple(v, (CSR_BASE + 0x100cL));
;         addi a1, zero, 0x6
;         stpi a1, s3, 0xc
;                 ; sdram_dfii_pi0_baddress_write(1);
;                         ; csr_write_simple(v, (CSR_BASE + 0x1010L));
;         addi a1, zero, 1
;         stpi a1, s3, 0x10
;                 ; command_p0(DFII_COMMAND_RAS|DFII_COMMAND_CAS|DFII_COMMAND_WE|DFII_COMMAND_CS);
;                         ; sdram_dfii_pi0_command_write(cmd);
;                                 ; csr_write_simple(v, (CSR_BASE + 0x1004L));
;         addi a1, zero, 0b1111
;         stpi a1, s3, 0x4
;                         ; sdram_dfii_pi0_command_issue_write(1);
;                                 ; csr_write_simple(v, (CSR_BASE + 0x1008L));
;         addi a1, zero, 1
;         stpi a1, s3, 0x8

;                 ; /* Load Mode Register 0, CL=6, BL=8 */
;                 ; sdram_dfii_pi0_address_write(0x320);
;                         ; csr_write_simple(v, (CSR_BASE + 0x100cL));
;         addi a1, zero, 0x320
;         stpi a1, s3, 0xc
;                 ; sdram_dfii_pi0_baddress_write(0);
;                         ; csr_write_simple(v, (CSR_BASE + 0x1010L));
;         stpi zero, s3, 0x10
;                 ; command_p0(DFII_COMMAND_RAS|DFII_COMMAND_CAS|DFII_COMMAND_WE|DFII_COMMAND_CS);
;                         ; sdram_dfii_pi0_command_write(cmd);
;                                 ; csr_write_simple(v, (CSR_BASE + 0x1004L));
;         addi a1, zero, 0b1111
;         stpi a1, s3, 0x4
;                 ; cdelay(200);
;         addi a0, zero, 200
;         j ra, cdelay

;                 ; /* ZQ Calibration */
;                 ; sdram_dfii_pi0_address_write(0x400);
;                         ; csr_write_simple(v, (CSR_BASE + 0x100cL));
;         subi a1, zero, 0x400 ; 0x400 ~= -1024 --> a1 = 0 - (-1024)
;         stpi a1, s3, 0xc
;                 ; sdram_dfii_pi0_baddress_write(0);
;                         ; csr_write_simple(v, (CSR_BASE + 0x1010L));
;         stpi zero, s3, 0x10
;                 ; command_p0(DFII_COMMAND_WE|DFII_COMMAND_CS);
;         addi a1, zero, 0b11
;         stpi a1, s3, 0x4
;                 ; cdelay(200);
;         addi a0, zero, 200
;         j ra, cdelay

; 	; sdram_leveling();
;                 ; int module;
;                 ; int dq_line;
;                 ; sdram_software_control_on();
;         j ra, software_control_on
;         ; for this implementation, DQ_COUNT=1, so we can eliminate the inner loop

;                 ; for(module=0; module<SDRAM_PHY_MODULES; module++) {
;                 ;     for (dq_line = 0; dq_line < DQ_COUNT; dq_line++) {
;         lui s3, 0
; leveling_rst_loop:
; 	        ;         sdram_leveling_action(module, dq_line, read_rst_dq_delay);
;         add a0, zero, s3
;         lui a1, 0
;         lui a2, read_rst_dq_delay
;         addi a2, a2, read_rst_dq_delay
;         j ra, sdram_leveling_action
;                 ;         sdram_leveling_action(module, dq_line, read_rst_dq_bitslip);
;         add a0, zero, s3
;         lui a1, 0
;         lui a2, read_rst_dq_bitslip
;         addi a2, a2, read_rst_dq_bitslip
;         j ra, sdram_leveling_action

;         addi s3, s3, 1
;         ltui a0, s3, 2
;     ?a0 j zero, leveling_rst_loop

;                 ; printf("Read leveling:\n");
;         lui a0, msg_dram_read_leveling
;         addi a0, a0, msg_dram_read_leveling
;         j ra, puts

;         	; sdram_read_leveling();
;                         ; int bitslip;
;                         ; unsigned int score;
;                         ; unsigned int best_score;
;                         ; int best_bitslip;
        
;         ; again, we can eliminate the inner loop
;                         ; for(module=0; module<SDRAM_PHY_MODULES; module++) {
;                         ; 	for (dq_line = 0; dq_line < DQ_COUNT; dq_line++) {
;         lui s3, 0
; leveling_calib_loop:
;                         ; 		/* Scan possible read windows */
;                         ; 		best_score = 0;
;         addi sp, sp, -8
;         stpi zero, sp, 0
;                         ; 		best_bitslip = 0;
;         stpi zero, sp, 4
;                         ; 		sdram_leveling_action(module, dq_line, read_rst_dq_bitslip);
;                 ;         sdram_leveling_action(module, dq_line, read_rst_dq_bitslip);
;         add a0, zero, s3
;         lui a1, 0
;         lui a2, read_rst_dq_bitslip
;         addi a2, a2, read_rst_dq_bitslip
;         j ra, sdram_leveling_action
;                         ; 		for(bitslip=0; bitslip<SDRAM_PHY_BITSLIPS; bitslip++) {
;         lui s4, 0
; leveling_bitslip_loop:
;                         ; 			/* Compute score */
;                         ; 			score = sdram_read_leveling_scan_module(module, bitslip, 1, dq_line);
;                                 ; const unsigned int max_errors = _seed_array_length*READ_CHECK_TEST_PATTERN_MAX_ERRORS; // = 192
;                                 ; int i;
;                                 ; unsigned int score;
;                                 ; unsigned int errors;

;                                 ; /* Check test pattern for each delay value */
;                                 ; score = 0;
;                                 ; if (show) // always true
;                                 ; 	printf("  m%d, b%02d: |", module, bitslip);
;         lui a0, msg_leveling_prefix
;         addi a0, a0, msg_leveling_prefix
;         j ra, puts
;         add a0, zero, s3
;         j ra, putx
;         lui a0, msg_leveling_comma
;         addi a0, a0, msg_leveling_comma
;         j ra, puts
;         add a0, zero, s4
;         j ra, putx
;         lui a0, msg_leveling_startbar
;         addi a0, a0, msg_leveling_startbar
;         j ra, puts
;                                 ; sdram_leveling_action(module, dq_line, read_rst_dq_delay);
;         add a0, zero, s3
;         lui a1, 0
;         lui a2, read_rst_dq_delay
;         addi a2, a2, read_rst_dq_delay
;         j ra, sdram_leveling_action

;                                 ; for(i=0;i<SDRAM_PHY_DELAYS;i++) {
;         lui s5, 0
; leveling_phy_delay_loop:
;                                 ; 	int working;
;                                 ; 	int _show = (i%MODULO == 0) & show;
;                                 ; 	errors = run_test_pattern(module, dq_line);
;         add a0, zero, s3
;         j ra, run_test_pattern ; this function hangs currently
;                                 ; 	working = errors == 0;
;         eqi a1, a0, 0
;                                 ; 	/* When any scan is working then the final score will always be higher then if no scan was working */
;                                 ; 	score += (working * max_errors*SDRAM_PHY_DELAYS) + (max_errors - errors); // max_errors = 3*64
;         sli a2, a1, 9
;         sli a1, a1, 10
;         add a1, a2, a1 ; a1 = working * (max_errors*SDRAM_PHY_DELAYS /*=3*64*8*/)
;         addi a1, a1, 192 ; a1 = working * (max_errors*SDRAM_PHY_DELAYS) + max_errors
;         sub a1, a1, a0 ; a1 = (working * max_errors*SDRAM_PHY_DELAYS) + (max_errors - errors)
;                                         ; score += a1
;         j zero, done ; TODO REMOVE
;                                 ; 	if (_show) {
;                                 ; 		print_scan_errors(errors);
;                                 ; 	}
;                                 ; 	sdram_leveling_action(module, dq_line, read_inc_dq_delay);
;                                 ; }
;         addi s5, s5, 1
;         ltui a0, s5, 8 ; SDRAM_PHY_DELAYS
;     ?a0 j zero, leveling_phy_delay_loop
;                                 ; if (show)
;                                 ; 	printf("| ");
;         lui a0, msg_leveling_endbar
;         addi a0, a0, msg_leveling_endbar
;         j ra, puts
        
;                         ; 			sdram_leveling_center_module(module, 1, 0,
;                         ; 				read_rst_dq_delay, read_inc_dq_delay, dq_line);
;                         ; 			printf("\n");
;                         ; 			if (score > best_score) {
;                         ; 				best_bitslip = bitslip;
;                         ; 				best_score = score;
;                         ; 			}
;                         ; 			/* Exit */
;                         ; 			if (bitslip == SDRAM_PHY_BITSLIPS-1)
;                         ; 				break;
;                         ; 			/* Increment bitslip */
;                         ; 			sdram_leveling_action(module, dq_line, read_inc_dq_bitslip);
;                         ; 		}
;         addi s4, s4, 1
;         ltui a0, s4, 4 ; SDRAM_PHY_BITSLIPS
;     ?a0 j zero, leveling_bitslip_loop

;                         ; 		/* Select best read window */
;                         ; 		printf("  best: m%d, b%02d ", module, best_bitslip);
;                         ; 		sdram_leveling_action(module, dq_line, read_rst_dq_bitslip);
;                         ; 		for (bitslip=0; bitslip<best_bitslip; bitslip++)
;                         ; 			sdram_leveling_action(module, dq_line, read_inc_dq_bitslip);

;                         ; 		/* Re-do leveling on best read window*/
;                         ; 		sdram_leveling_center_module(module, 1, 0,
;                         ; 			read_rst_dq_delay, read_inc_dq_delay, dq_line);
;                         ; 		printf("\n");
;                         ; 	}
;                         ; }
;         addi s3, s3, 1
;         ltui a0, s4, 2
;     ?a0 j zero, leveling_calib_loop

;                         ; with module=0, dq_line=0:
;                         ; /* Scan possible read windows */
;                         ; best_score = 0;
;                         ; best_bitslip = 0;
;                         ; sdram_leveling_action(module, dq_line, read_rst_dq_bitslip);
;                         ; for(bitslip=0; bitslip<SDRAM_PHY_BITSLIPS; bitslip++) {
;                         ;         /* Compute score */
;                         ;         score = sdram_read_leveling_scan_module(module, bitslip, 1, dq_line);
;                         ;         sdram_leveling_center_module(module, 1, 0,
;                         ;                 read_rst_dq_delay, read_inc_dq_delay, dq_line);
;                         ;         printf("\n");
;                         ;         if (score > best_score) {
;                         ;                 best_bitslip = bitslip;
;                         ;                 best_score = score;
;                         ;         }
;                         ;         /* Exit */
;                         ;         if (bitslip == SDRAM_PHY_BITSLIPS-1)
;                         ;                 break;
;                         ;         /* Increment bitslip */
;                         ;         sdram_leveling_action(module, dq_line, read_inc_dq_bitslip);
;                         ; }

;                         ; /* Select best read window */
;                         ; printf("  best: m%d, b%02d ", module, best_bitslip);
;                         ; sdram_leveling_action(module, dq_line, read_rst_dq_bitslip);
;                         ; for (bitslip=0; bitslip<best_bitslip; bitslip++)
;                         ;         sdram_leveling_action(module, dq_line, read_inc_dq_bitslip);

;                         ; /* Re-do leveling on best read window*/
;                         ; sdram_leveling_center_module(module, 1, 0,
;                         ;         read_rst_dq_delay, read_inc_dq_delay, dq_line);
;                         ; printf("\n");
;                 ; sdram_software_control_off();

; 	; sdram_software_control_off();
; 	; if(!memtest((unsigned int *) MAIN_RAM_BASE, MEMTEST_DATA_SIZE)) {
; 	; 	ddrctrl_init_error_write(1);
; 	; 	ddrctrl_init_done_write(1);
; 	; 	return 0;
; 	; }
; 	; memspeed((unsigned int *) MAIN_RAM_BASE, MEMTEST_DATA_SIZE, false, 0);
; 	; ddrctrl_init_done_write(1);

; done:
;         lui a0, msg_done
;         addi a0, a0, msg_done
;         j ra, puts

; halt:   j zero, halt            ; halt


; cdelay:
;         subi a0, a0, 1
;     ?a0 j zero, cdelay
;         jx zero, zero, ra

; software_control_on:
;                 ; previous = sdram_dfii_control_read();
;                         ; return csr_read_simple((CSR_BASE + 0x1000L));
;         lui a0, 0x11000
;         ldpi a1, a0, 0
;                 ; if (previous != DFII_CONTROL_SOFTWARE) {
;         xori a1, a1, 0b1110
;     !a1 j zero, dram_skip_swmode
;                 ;     sdram_dfii_control_write(DFII_CONTROL_SOFTWARE);
;                         ; csr_write_simple(v, (CSR_BASE + 0x1000L));
;         addi a2, zero, 0b1110
;         stpi a2, a0, 0
;                 ; 	printf("Switching SDRAM to software control.\n");
;         lui a0, msg_dram_sw_mode
;         addi a0, a0, msg_dram_sw_mode
;         addi sp, sp, -4
;         stpi ra, sp, 0
;         j ra, puts
;         ldpi ra, sp, 0
;         addi sp, sp, 4
; dram_skip_swmode:
;         jx zero, zero, ra

; read_rst_dq_delay:
; 	; /* Reset delay */
;         ; read_dq_delay[module] = 0;
;         sli a0, a0, 4
;         stpi zero, a0, 0
; 	; ddrphy_rdly_dq_rst_write(1);
;                 ; csr_write_simple(v, (CSR_BASE + 0x804L));
;         addi a0, zero, 1
;         lui a1, 0x10800
;         stpi a0, a1, 0x4
;         jx zero, zero, ra

; read_rst_dq_bitslip:
;         ; /* Reset bitslip */
; 	; read_dq_bitslip[module] = 0;
;         sli a0, a0, 4
;         addi a0, a0, 8
;         stpi zero, a0, 0
; 	; ddrphy_rdly_dq_bitslip_rst_write(1);
;                 ; csr_write_simple(v, (CSR_BASE + 0x80cL));
;         addi a0, zero, 1
;         lui a1, 0x10800
;         stpi a0, a1, 0xC
;         jx zero, zero, ra


; sdram_leveling_action:
;         ; 	/* Select module */
; 	; sdram_select(module, dq_line);
;                 ; ddrphy_dly_sel_write(1 << module);
;                         ; csr_write_simple(v, (CSR_BASE + 0x800L));
;         lui a4, 0x10800
;         addi a3, zero, 1
;         sl a3, a3, a0
;         stpi a0, s2, 0

; 	; /* Action */
; 	; action(module);
;         addi sp, sp, -8
;         stpi ra, sp, 0
;         stpi a0, sp, 4
;         jx ra, zero, a2
;         ldpi ra, sp, 0
;         ldpi a0, sp, 4
;         addi sp, sp, 8

; 	; /* Un-select module */
;                         ; sdram_deselect(module, dq_line);
;                                 ; ddrphy_dly_sel_write(0);
;                                         ; csr_write_simple(v, (CSR_BASE + 0x800L));
;         lui a4, 0x10800
;         stpi zero, a4, 0
;                                 ; /* Sync all DQSBUFM's, By toggling all dly_sel (DQSBUFM.PAUSE) lines. */
;                                 ; ddrphy_dly_sel_write(0xff);
;                                         ; csr_write_simple(v, (CSR_BASE + 0x800L));
;         addi a0, zero, 0xFF
;         stpi a0, a4, 0
;                         	; ddrphy_dly_sel_write(0);
;                                         ; csr_write_simple(v, (CSR_BASE + 0x800L));
;         stpi zero, a4, 0
;         jx zero, zero, ra

; run_test_pattern: ; a0 = module, ignoring dq_line
;         addi sp, sp, -64 ; int ra, s2, s3, s4, s5; char tst[8]; char prs[2][8]; int scratch[3]; int module; unalloc;
;         stpi ra, sp, 0
;         stpi s2, sp, 4
;         stpi s3, sp, 8
;         stpi s4, sp, 12
;         stpi s5, sp, 16
;         stpi a0, sp, 56
;         ; tst = sp+20
;         ; prs = sp+28
;         ; scratch = sp+44
;         ; module = sp+56

; 	; int errors = 0;
;         lui s2, 0
; 	; for (int i = 0; i < _seed_array_length; i++) {
;         lui s3, 0
; run_test_pattern_loop:
; 	; 	errors += sdram_write_read_check_test_pattern(module, _seed_array[i], dq_line);
;                 ; int p, i, bit;
;                 ; unsigned int errors;
;                 ; unsigned int prv;
;                 ; unsigned char value;
;                 ; unsigned char tst[DFII_PIX_DATA_BYTES];
;                 ; unsigned char prs[SDRAM_PHY_PHASES][DFII_PIX_DATA_BYTES];
;                 ; /* Generate pseudo-random sequence */
;                 ; prv = seed;
;         lui s4, seed_array
;         addi s4, s4, seed_array
;         sli a0, s3, 2
;         ldp s4, s4, a0 ; prv = seed_array[i]
;                 ; for(p=0;p<SDRAM_PHY_PHASES;p++) {
;         stpi s2, sp, 44
;         stpi s3, sp, 48
;         stpi s4, sp, 52 ; prv
;         lui s5, 0
; test_pattern_phase_loop:
;                 ; 	for(i=0;i<DFII_PIX_DATA_BYTES;i++) {
;         lui s2, 0
; test_pattern_pix_loop:
;                 ; 		value = 0;
;         lui s3, 0
;                 ; 		for (bit=0;bit<8;bit++) {
;         lui s4, 0
; test_pattern_bit_loop:
;                 ; 			prv = lfsr(32, prv);
;         ldpi a0, sp, 52
;         j ra, lfsr32
;         stpi a0, sp, 52
;                 ; 			value |= (prv&1) << bit;
;         andi a0, a0, 1
;         sl a0, a0, s4
;         or s3, s3, a0
;                 ; 		}
;         addi s4, s4, 1
;         ltui a0, s4, 8
;     ?a0 j zero, test_pattern_bit_loop
;                 ; 		prs[p][i] = value;
;         ; p(0..2) = s5
;         ; i(0..8) = s2
        
;         ; bit_pos = (i & 0b11)*8
;         andi a2, s2, 0b11
;         sli a2, a2, 3
;         ; mask = ~(0xFF << bit_pos)
;         addi a3, zero, 0xFF
;         sl a3, a3, a2
;         xori a3, a3, -1
;         ; addr = (p*8 + i) & ~0b11 = (p<<3 + i) & ~0b11
;         sli a0, s5, 3
;         add a0, a0, s2
;         andi a0, a0, -4
;         ; ptr = addr + sp + 28
;         addi a0, a0, 28
;         ; *ptr = *ptr & mask | (value << bit_pos)
;         ldp a1, a0, sp
;         and a1, a1, a3
;         sl a3, s3, a2
;         or a1, a1, a3
;         stp a1, a0, sp
;                 ; 	}
;         addi s2, s2, 1
;         ltui a0, s2, 8 ; PIX_DATA_BYTES
;     ?a0 j zero, test_pattern_pix_loop
;                 ; }
;         addi s5, s5, 1
;         ltui a0, s5, 2 ; SDRAM_PHY_PHASES
;     ?a0 j zero, test_pattern_phase_loop
;         ; ldpi s4, sp, 52 ; discard s4 (prv)

;         lui s3, 0x11000 ; s3 = CSR_BASE + 0x1000
;                 ; /* Activate */
;                 ; sdram_activate_test_row();
;                         ; sdram_dfii_pi0_address_write(0);
;                                 ; csr_write_simple(v, (CSR_BASE + 0x100cL));
;         stpi zero, s3, 0xc
;                         ; sdram_dfii_pi0_baddress_write(0);
;                                 ; csr_write_simple(v, (CSR_BASE + 0x1010L));
;         stpi zero, s3, 0x10
;                         ; command_p0(DFII_COMMAND_RAS|DFII_COMMAND_CS);
;                                 ; sdram_dfii_pi0_command_write(cmd);
;                                         ; csr_write_simple(v, (CSR_BASE + 0x1004L));
;         addi a1, zero, 0b1001
;         stpi a1, s3, 0x4
;                         ; cdelay(15);
;         addi a0, zero, 15
;         j ra, cdelay

;         ; Because we only have 2 phases, we can save ourselves some trouble by
;         ; unrolling this loop
;                 ; /* Write pseudo-random sequence */
;                 ; for(p=0;p<SDRAM_PHY_PHASES;p++) {
;                 ; 	csr_wr_buf_uint8(sdram_dfii_pix_wrdata_addr(p), prs[p], DFII_PIX_DATA_BYTES);
;                 ; }
;         ; in fact, we can save ourselves a lot of work by just writing the test
;         ; values to CSRs 32 bits at a time, because that's what csr_wr... does
;         ; anyway

;         ldpi a0, sp, 28
;         stpi a0, s3, 0x14
;         ldpi a0, sp, 32
;         stpi a0, s3, 0x18
;         ldpi a0, sp, 36
;         stpi a0, s3, 0x34
;         ldpi a0, sp, 40
;         stpi a0, s3, 0x38        
        
;                 ; sdram_dfii_piwr_address_write(0);
;                         ; unsigned char wrphase = sdram_dfii_get_wrphase(); // 1
;                         ; sdram_dfii_pix_address_write(wrphase, value);
;                                 ; sdram_dfii_pi1_address_write(value);
;                                 	; csr_write_simple(v, (CSR_BASE + 0x102cL));
;         stpi zero, s3, 0x2C
;                 ; sdram_dfii_piwr_baddress_write(0);
;                         ; unsigned char wrphase = sdram_dfii_get_wrphase(); // 1
;                         ; sdram_dfii_pix_baddress_write(wrphase, value);
;                                 ; sdram_dfii_pi1_baddress_write(value);
; 	                                ; csr_write_simple(v, (CSR_BASE + 0x1030L));
;         stpi zero, s3, 0x30
;                 ; command_pwr(DFII_COMMAND_CAS|DFII_COMMAND_WE|DFII_COMMAND_CS|DFII_COMMAND_WRDATA);
;                         ; unsigned char wrphase = sdram_dfii_get_wrphase(); // 1
;                         ; command_px(wrphase, value);
;                                 ; command_p1(value);
;                                         ; sdram_dfii_pi1_command_write(cmd);
;                                                 ; csr_write_simple(v, (CSR_BASE + 0x1024L));
;         addi a0, zero, 0b10111
;         stpi a0, s3, 0x24
;                                         ; sdram_dfii_pi1_command_issue_write(1);
;                                                 ; csr_write_simple(v, (CSR_BASE + 0x1028L));
;         addi a0, zero, 1
;         stpi a0, s3, 0x28
;                 ; cdelay(15);
;         addi a0, zero, 15
;         j ra, cdelay
        
;                 ; ddrphy_burstdet_clr_write(1);
;                 	; csr_write_simple(v, (CSR_BASE + 0x814L));
;         lui a1, 0x10800
;         addi a0, zero, 1
;         stpi a0, a1, 0x14

;                 ; /* Read/Check pseudo-random sequence */
;                 ; sdram_dfii_pird_address_write(0);
;                         ; unsigned char rdphase = sdram_dfii_get_rdphase(); // 0
;                 	; sdram_dfii_pix_address_write(rdphase, value);
;                                 ; sdram_dfii_pi0_address_write(value);
;                                         ; csr_write_simple(v, (CSR_BASE + 0x100cL));
;         stpi zero, s3, 0xc
;                 ; sdram_dfii_pird_baddress_write(0);
;                 	; unsigned char rdphase = sdram_dfii_get_rdphase();
; 	                ; sdram_dfii_pix_baddress_write(rdphase, value);
;                                 ; sdram_dfii_pi0_baddress_write(value);
;                                 	; csr_write_simple(v, (CSR_BASE + 0x1010L));
;         stpi zero, s3, 0x10
;                 ; command_prd(DFII_COMMAND_CAS|DFII_COMMAND_CS|DFII_COMMAND_RDDATA);
;                         ; unsigned char rdphase = sdram_dfii_get_rdphase(); // 0
;                         ; command_px(rdphase, value);
;                                 ; command_p0(value);
;                                         ; sdram_dfii_pi0_command_write(cmd);
;                                                 ; csr_write_simple(v, (CSR_BASE + 0x1004L));
;         addi a0, zero, 0x25
;                                         ; sdram_dfii_pi0_command_issue_write(1);
;                                                 ; csr_write_simple(v, (CSR_BASE + 0x1008L));
;                 ; cdelay(15);
;         addi a0, zero, 15
;         j ra, cdelay

;                 ; /* Precharge */
;                 ; sdram_precharge_test_row();
;                         ; sdram_dfii_pi0_address_write(0);
;                                 ; csr_write_simple(v, (CSR_BASE + 0x100cL));
;         stpi zero, s3, 0xc
;                         ; sdram_dfii_pi0_baddress_write(0);
;                                 ; csr_write_simple(v, (CSR_BASE + 0x1010L));
;         stpi zero, s3, 0x10
;                         ; command_p0(DFII_COMMAND_RAS|DFII_COMMAND_WE|DFII_COMMAND_CS);
;                                 ; sdram_dfii_pi0_command_write(cmd);
;                                         ; csr_write_simple(v, (CSR_BASE + 0x1004L));
;         addi a0, zero, 0b1011
;         stpi a0, s3, 0x4
;                         ; cdelay(15);
;         addi a0, zero, 15
;         j ra, cdelay
;                 ; errors = 0;
;         lui s2, 0
;                 ; for(p=0;p<SDRAM_PHY_PHASES;p++) {
;         lui s5, 0
; test_pattern_readback_loop:
;         ; at least here
;                 ; 	/* Read back test pattern */
;                 ; 	csr_rd_buf_uint8(sdram_dfii_pix_rddata_addr(p), tst, DFII_PIX_DATA_BYTES);
;                         ; a1 = sdram_dfii_pix_rddata_addr(p)
;         add a1, zero, s3
;     ?s5 addi a1, a1, 0x20

;         ldpi a0, a1, 0x1C
;         stpi a0, sp, 20
;         ldpi a0, a1, 0x20
;         stpi a0, sp, 24

;                 ; 	/* Verify bytes matching current 'module' */
;                 ; 	int pebo;   // module's positive_edge_byte_offset
;                 ; 	int nebo;   // module's negative_edge_byte_offset, could be undefined if SDR DRAM is used
;                 ; 	int ibo;    // module's in byte offset (x4 ICs)
;                 ; 	int mask;   // Check data lines

;                 ; 	mask = MODULE_BITMASK; // 0xFF

;                 ; 	/* Values written into CSR are Big Endian */
;                 ; 	/* SDRAM_PHY_XDR is define 1 if SDR and 2 if DDR*/
;                 ; 	nebo = (DFII_PIX_DATA_BYTES / SDRAM_PHY_XDR) - 1 - (module * SDRAM_PHY_DQ_DQS_RATIO)/8;
;                         ; nebo = 3 - module
;                                 ; except we actually save data as LE instead of
;                                 ; BE as the example code does, so nebo is just module
;                                 ; nebo = module
;         ldpi a1, sp, 56 ; a1 = nebo
;                 ; 	pebo = nebo + DFII_PIX_DATA_BYTES / SDRAM_PHY_XDR;
;                         ; pebo = nebo + 4
;         addi a2, a1, 4  ; a2 = pebo
;                 ;       // skipped: not using x4 ICs
;                 ; 	errors += popcount(((prs[p][pebo] >> ibo) & mask) ^
;                 ; 	                   ((tst[pebo] >> ibo) & mask));
;                         ; 	errors += popcount((prs[p][pebo] & mask) ^ (tst[pebo] & mask));
;         ; conveniently, nebo will always be in the first word, and pebo will
;         ; always be in the second, so we can turn the indexes into shifts
;         ; convert nebo & pebo to bits
;         sli a1, a1, 3
;         sli a2, a2, 3
;         addi a3, sp, 28 ; a3 = prs
;     ?s5 addi a3, a3, 8  ; a3 = &prs[p] (this only works because p is either 0 or 1)
        
;         ldpi a4, a3, 0  ; a4 = prs[p][0..3]
;         ldpi a5, sp, 20 ; a5 = tst[0..3]
;         xor a4, a4, a5  ; a4 = a4 ^ a5
;         sr a4, a4, a2   ; a4 >>= pebo
;         andi a4, a4, 0xFF ; a4 = (a4 ^ a5) & mask
;         ; since we only compare errors in 8 bits at a time, we
;         ; can use only one call to popcount by masking the two
;         ; results together into a single halfword
;         sli a0, a4, 8
;                 ;       // skipped: SDRAM_PHY_DQ_DQS_RATIO == 8
;                 ;       // skipped: not using x4 ICs
;                 ; 	errors += popcount(((prs[p][nebo] >> ibo) & mask) ^
;                 ; 	                   ((tst[nebo] >> ibo) & mask));
;                         ; 	errors += popcount((prs[p][nebo] & mask) ^ (tst[nebo] & mask));
        
;                 ;       // skipped: SDRAM_PHY_DQ_DQS_RATIO == 8
;         ldpi a4, a3, 4  ; a4 = prs[p][0..3]
;         ldpi a5, sp, 24 ; a5 = tst[4..7]
;         xor a4, a4, a5  ; a4 = a4 ^ a5
;         sr a4, a4, a1   ; a4 >>= nebo
;         andi a4, a4, 0xFF ; a4 = (a4 ^ a5) & mask
;         ; pack the other byte into the leftover 8 bits of our word
;         or a0, a0, a4

;         j ra, popcount
;         add s2, s2, a0
;                 ; }
;         addi s5, s5, 1
;         ltui a0, s5, 2
;     ?a0 j zero, test_pattern_readback_loop
;         ; at most here
        
;                 ; if (((ddrphy_burstdet_seen_read() >> module) & 0x1) != 1)
;                         ; return csr_read_simple((CSR_BASE + 0x818L));
;         lui a1, 0x10800 ; a1 = CSR_BASE + 0x800
;         ldpi a1, a1, 0x18 ; a1 = ddrphy_burstdet_seen_read()
;         ldpi a2, sp, 56 ; a2 = module
;         sr a1, a1, a2 ; a1 = (ddrphy_burstdet_seen_read() >> module)
;         andi a1, a1, 1 ; a1 = ((ddrphy_burstdet_seen_read() >> module) & 0x1)
;                 ; 	errors += 1;
;     !a1 addi s2, s2, 1

;         add a0, zero, s2
;         ldpi s2, sp, 44 ; outside loop's errors
;         add s2, s2, a0 ; errors += sdram_write_read_check_test_pattern(module, _seed_array[i], dq_line);
;         ldpi s3, sp, 48

; 	; }
;         addi s3, s3, 1
;         ltui a0, s3, 3
;     ?a0 j zero, run_test_pattern_loop

; 	; return errors;
;         add a0, zero, s2
;         ldpi ra, sp, 0
;         ldpi s2, sp, 4
;         ldpi s3, sp, 8
;         ldpi s4, sp, 12
;         ldpi s5, sp, 16
;         addi sp, sp, 128
;         jx zero, zero, ra

; lfsr32:
;         ; rather than store the whole table, we just specialize bits=32
;         ; (which means taps[bits] = 0x80200003)

;         ; unsigned long lsb = prev & 1;
;         andi a1, a0, 1

;         ; prev >>= 1;
;         sri a0, a0, 1
;         ; prev ^= (-lsb) & lfsr_taps[bits];
;         sub a1, zero, a1
;         lui a2, 0x80200003
;         addi a2, a2, 0x80200003
;         and a1, a1, a2
;         xor a0, a0, a1

;         ; return prev;
;         jx zero, zero, ra

; popcount:
;         ; technically this is only used once, but it's a useful function so I'm
;         ; keeping it here anyway
; 	; however, it gets a while loop instead of the fancy bitmask
;         ; version because I'm not convinced loading that many constants is worth
;         ; the tiny speedup and ROM space is probably more valuable anyway
;         lui a1, 0
; popcount_loop:
;         andi a2, a0, 1
;     ?a2 addi a1, a1, 1
;         sri a0, a0, 1
;     ?a0 j zero, popcount_loop
;         add a1, zero, a0
;         jx zero, zero, ra        

; print_scan_errors:
; ; static void print_scan_errors(unsigned int errors) {
; ; #ifdef SDRAM_LEVELING_SCAN_DISPLAY_HEX_DIV
; ; 	// Display '.' for no errors, errors/div in hex if it is a single char, else show 'X'
; ; 	errors = errors / SDRAM_LEVELING_SCAN_DISPLAY_HEX_DIV;
; ; 	if (errors == 0)
; ; 		printf(".");
; ; 	else if (errors > 0xf)
; ; 		printf("X");
; ; 	else
; ; 		printf("%x", errors);
; ; #else
; ; 		printf("%d", errors == 0);
; ; #endif // SDRAM_LEVELING_SCAN_DISPLAY_HEX_DIV
; ; }
;     ?a0 addi a0, zero, 1
;         xori a0, a0, 1
;         addi a0, a0, 48 ; '0'
;         ; putchar
;         lui a4, 0x01000000
;         stpi a0, a4, 8
;         jx zero, zero, ra

;         ; Put string to TTY
; puts:                           ; void puts(word* p)
;         lui a4, 0x01000000      ; preload address of TTY
; puts_loop:                      
;         addi a2, zero, 4        ; i = 4
;         ldpi a1, a0, 0          ; v = *p
; puts_shiftloop:
;         andi a3, a1, 0xFF       ; c = v & 0xFF
;     !a3 jx zero, zero, ra       ; if(c == 0) return
;         stpi a3, a4, 8          ; putchar(c)
;         subi a2, a2, 1          ; i--
;         sri a1, a1, 8           ; v >>= 8
;     ?a2 j zero, puts_shiftloop  ; if(i != 0) goto puts_shiftloop
;         addi a0, a0, 4          ; p += 4
;         j zero, puts_loop       ; goto puts_loop

;         ; Put hexadecimal word to TTY
; putx:
;         lui a4, 0x01000000      ; preload address of TTY
;         addi a3, zero, 8               ; i = 8
; putx_loop:
;         sri a1, a0, 28          ; nibble = word >> 28
;         ltui a2, a1, 10          ; isnum = (nibble < 10)
;     !a2 addi a1, a1, 87         ; if(isnum) nibble += 'a' - 10
;     ?a2 addi a1, a1, 48         ; else nibble += '0'
;         stpi a1, a4, 8          ; putchar(nibble)
;         subi a3, a3, 1          ; i--
;         sli a0, a0, 4           ; word <<= 4
;     ?a3 j zero, putx_loop       ; if(i != 0) goto putx_loop
;         jx zero, zero, ra       ; return

; ; static int _seed_array[] = {42, 84, 36};
; ; static int _seed_array_length = sizeof(_seed_array) / sizeof(_seed_array[0]);
; seed_array:
;         const 42
;         const 84
;         const 36

;         string msg_start "MOLLUSC bootloader starting...\r\n"
;         string msg_dram_init "Initializing DRAM @0x"
;         string msg_dram_init_after "...\r\n"
;         string msg_dram_sw_mode "Switching SDRAM to software control.\r\n"
;         string msg_dram_read_leveling "Read leveling:\r\n"
;         string msg_leveling_prefix "  m"
;         string msg_leveling_comma ", b"
;         string msg_leveling_startbar ": |"
;         string msg_leveling_endbar "| "
;         string msg_endl "\r\n"

;         string msg_done "Boot sequence complete, halting.\r\n"
