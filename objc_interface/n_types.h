#ifndef __N_TYPES_H__
#define __N_TYPES_H__

/* This is a patch for https://github.com/Araq/Nimrod/issues/826.
 *
 * Stargate: if you change here something, please change l_types.nim as
 * well.
 */
enum Weight_type_enum
{
    kilograms = 0,
    pounds = 1,
};

typedef enum Weight_type_enum Weight_type;

#endif // __N_TYPES_H__
