/* 
 * File:   recording.h
 * Author: beni
 *
 * Created on 17 January 2010, 13:41
 */

#ifndef _RECORDING_H
#define	_RECORDING_H

#define RECORDING_MAX_SAMPLES (44100*60)

#ifdef	__cplusplus
extern "C" {
#endif

    typedef float sample;

    typedef struct {
        sample *signal;
        unsigned int samples_number;
        unsigned int sample_rate;
    } recording;

    typedef struct {
        sample minimum;
        sample maximum;
    }extrema;

    float recording_length(recording *rec);
    int recording_new_from_file(char *path, recording **rec);
    void recording_slot_extrema(recording *rec, unsigned int start, unsigned int length, extrema *extrema);

#ifdef	__cplusplus
}
#endif

#endif	/* _RECORDING_H */

