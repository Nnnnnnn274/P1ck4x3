#include <assert.h>
#include <math.h>
#include <stdio.h>

#include "../lara/kexploit/pe/EagleGalleryPosition.h"

int main(void) {
    assert(eagle_gallery_position_component(0) == 0);
    assert(eagle_gallery_position_component(NAN) == 0);
    assert(eagle_gallery_position_component(INFINITY) == 0);
    assert(eagle_gallery_position_component(-INFINITY) == 0);
    assert(eagle_gallery_position_component(1000) == 12);
    assert(eagle_gallery_position_component(-1000) == -12);
    assert(eagle_gallery_position_component(0.125) == 0.25);
    assert(eagle_gallery_position_component(-0.125) == -0.25);

    for (int index = -12000; index <= 12000; index++) {
        double raw = index / 1000.0;
        double value = eagle_gallery_position_component(raw);
        assert(value >= -12 && value <= 12);
        assert(value * 4 == round(value * 4));
        assert(eagle_gallery_position_component(value) == value);
        assert(eagle_gallery_position_component(-raw) == -value);
    }

    puts("PASS: Gallery position bounds, quarter-point steps and invalid inputs");
}
