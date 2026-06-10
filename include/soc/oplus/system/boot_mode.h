/* Stub: sm8550-modules not checked out; provide minimal definitions inline. */
#ifndef _OPLUS_SYSTEM_BOOT_MODE_H
#define _OPLUS_SYSTEM_BOOT_MODE_H

enum MSM_BOOT_MODES {
	MSM_BOOT_MODE__NORMAL		= 0,
	MSM_BOOT_MODE__FASTBOOT		= 1,
	MSM_BOOT_MODE__RECOVERY		= 2,
	MSM_BOOT_MODE__CHARGE		= 3,
	MSM_BOOT_MODE__FACTORY		= 4,
	MSM_BOOT_MODE__RF		= 5,
	MSM_BOOT_MODE__WLAN		= 6,
	MSM_BOOT_MODE__MOS		= 7,
	MSM_BOOT_MODE__FACTORY2		= 25,
	MSM_BOOT_MODE__SILENCE		= 21,
	MSM_BOOT_MODE__SAU		= 22,
};

static inline int get_boot_mode(void) { return MSM_BOOT_MODE__NORMAL; }

#endif /* _OPLUS_SYSTEM_BOOT_MODE_H */
