/*
 * Stand-in for the stock com.lab126.blanket LIPC service, which was part of
 * the removed framework. powerd ignores the power button while it believes the
 * boot splash is up, and it decides that by reading blanket's "load" property
 * (the list of loaded modules): an error counts as "splash loaded". This
 * service reports no modules and accepts load/unload requests.
 *
 * liblipc is loaded with dlopen so the build needs no Amazon headers or
 * libraries. Signatures follow NiLuJe's openlipc.h.
 */
#include <dlfcn.h>
#include <stdio.h>
#include <unistd.h>

typedef void LIPC;
typedef int LIPCcode;
typedef LIPCcode (*LipcPropCallback)(LIPC *, const char *, void *, void *);

enum { LIPC_OK = 0 };

static LIPCcode get_load(LIPC *lipc, const char *prop, void *value, void *data)
{
	(void)lipc;
	(void)prop;
	(void)data;
	((char *)value)[0] = '\0';
	return LIPC_OK;
}

static LIPCcode set_any(LIPC *lipc, const char *prop, void *value, void *data)
{
	(void)lipc;
	(void)data;
	dprintf(2, "blanketd: %s=%s\n", prop, value ? (const char *)value : "");
	return LIPC_OK;
}

int main(void)
{
	void *lib = dlopen("liblipc.so.1", RTLD_NOW);
	if (!lib) {
		dprintf(2, "blanketd: %s\n", dlerror());
		return 1;
	}
	LIPC *(*open_service)(const char *) = dlsym(lib, "LipcOpen");
	LIPCcode (*reg_string)(LIPC *, const char *, LipcPropCallback, LipcPropCallback, void *) =
		dlsym(lib, "LipcRegisterStringProperty");
	if (!open_service || !reg_string) {
		dprintf(2, "blanketd: liblipc is missing LipcOpen or LipcRegisterStringProperty\n");
		return 1;
	}

	LIPC *lipc = open_service("com.lab126.blanket");
	if (!lipc) {
		dprintf(2, "blanketd: LipcOpen failed\n");
		return 1;
	}
	if (reg_string(lipc, "load", get_load, set_any, NULL) != LIPC_OK ||
	    reg_string(lipc, "unload", NULL, set_any, NULL) != LIPC_OK) {
		dprintf(2, "blanketd: property registration failed\n");
		return 1;
	}

	/* liblipc dispatches on its own thread. */
	for (;;)
		pause();
}
