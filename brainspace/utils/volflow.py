from nilearn import datasets
from nilearn.input_data import NiftiLabelsMasker
from nilearn.connectome import ConnectivityMeasure 
import numpy as np


def fmrivols2conn(fmri_filenames, atlas_filename, confounds_fn="", measure='correlation'):
    """
    Takes 4D fmri volumes from different and extracts the connectivity matrix
    Parameters
    ----------
    fmri_filenames: lists of paths  or path
        List Fullpath to functional images in nifti
    altas_filename: path
        Fullpath to the parcellation to create the FC matrix.
        Must be in the same space than functional 
    confounds_fn (optional): path
        Paths to a csv type files with the confound regressors for each dataset.
    measure: str
        {"correlation", "partial correlation", "tangent", "covariance", "precision"}, optional
    Returns
    -------
    FC_matrix: matrix
       Functional connectivy matrix of the image. 
    """
    # if user is only inputing one module adapt input so is accepted by the function
    if isinstance(fmri_filenames,str):
        fmri_filenames = [fmri_filenames]
        confounds_fn = [confounds_fn]
    # Create masker to extract the timeseries
    masker = NiftiLabelsMasker(labels_img=atlas_filename, standardize=True)
    # define the connectome measure
    connectome_measure = ConnectivityMeasure(kind=measure)
    timeseries = []
    # loop that extracts the timeseries for each volume
    for i,volume in enumerate(fmri_filenames):
        if confounds_fn[0] == "":
            timeseries.append(masker.fit_transform(volume).T)
        else:
            timeseries.append(masker.fit_transform(volume, confounds=confounds_fn[i]).T)
    timeseries = np.array(timeseries)
    mean_ts = np.mean(timeseries,axis=0)
    # call fit_transform from ConnectivityMeasure object
    FC_matrix = connectome_measure.fit_transform([mean_ts.T])[0]
    # saving each subject correlation to correlations
    return FC_matrix