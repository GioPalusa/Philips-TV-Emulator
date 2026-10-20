/* ARM Android uses cacheflush(start, end, flags), despite the generic header
 * parameter names. Supply flags=0; bare-metal libgcc's helper is a no-op. */
#include <unistd.h>
#include <stdlib.h>
void __clear_cache(void *start, void *end)
{
    if (cacheflush((long)start, (long)end, 0) != 0) abort();
}
