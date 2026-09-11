#ifndef INPUT_H
#define INPUT_H

#include "types.h"

void input_init(void);

void input_shutdown(void);

char input_get(void);

Direction input_to_direction(
    char input
);

#endif