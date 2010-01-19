#include <sndfile.h>
#include <malloc.h>
#include "recording.h"
#include "error.h"

#define MIN(A,B)  (A<B?A:B)

float recording_length(recording *rec) {
    return (double) rec->samples_number / rec->sample_rate;
}

void recording_slot_extrema(recording *rec, unsigned int start, unsigned int length, extrema *extrema) {
    unsigned int i;

    extrema->minimum = rec->signal[start];
    extrema->maximum = rec->signal[start];
    for (i = start + 1; i < start + length; i++) {
        if (rec->signal[i] < extrema->minimum) extrema->minimum = rec->signal[i];
        if (rec->signal[i] > extrema->maximum) extrema->maximum = rec->signal[i];
    }
}

int recording_new_from_file(char *path, recording **rec) {
    SNDFILE *sndf;
    SF_INFO finfo;
    unsigned int count;
    int error;
    unsigned int frames_to_read;

    *rec = (recording *) malloc(sizeof (recording));
    if (*rec == NULL) {
        errstr = "Not enough memory.";
        return -1;
    }

    /* Open file */
    sndf = sf_open(path, SFM_READ, &finfo);
    error = sf_error(sndf);
    if (error != 0) {
        /*
                errstr = sf_strerror(sndf);
         */
        return -1;
    }

    /* Check is a mono recording */
    if (finfo.channels != 1) {
        errstr = "Only mono files supported.";
        return -1;
    }

    /* Do not read more than MAX_FRAMES samples*/
    frames_to_read = MIN(finfo.frames, RECORDING_MAX_SAMPLES);

    (*rec)->signal = (sample *) malloc(sizeof (sample) * frames_to_read);
    if ((*rec)->signal == NULL) {
        errstr = "Not enough memory to read recording.";
        return -1;
    }

    count = sf_readf_float(sndf, (float *) (*rec)->signal, frames_to_read);
    if (count != frames_to_read) {
        errstr = "Error reading sound file. Frames requested and frames read do not match.";
    }

    (*rec)->samples_number = count;
    (*rec)->sample_rate = finfo.samplerate;

    return 0;
}