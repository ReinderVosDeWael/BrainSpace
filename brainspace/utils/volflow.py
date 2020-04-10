from nilearn import datasets
from nilearn.input_data import NiftiLabelsMasker
from nilearn.connectome import ConnectivityMeasure
import nibabel as nib
import numpy as np


def fmrivols2conn(fmri_input, atlas_filename, confounds_fn="", measure='correlation'):
    """
    Takes 4D fmri volumes from different and extracts the connectivity matrix
    Parameters
    ----------
    fmri_input: this variable can be:
        path Fullpath to functional images in nifti
        List of Fullpath to functional images in nifti
        nibabel nifti object
        list of nibabel nifti objects
    altas_filename: path
        Fullpath to the parcellation to create the FC matrix of nibabel object containin the atlas.
        Must be in the same space than functional images 
    confounds_fn (optional): path
        Paths to a csv type files with the confound regressors for each dataset.
    measure: str
        {"correlation", "partial correlation", "tangent", "covariance", "precision"}, optional
    Returns
    -------
    FC_matrix: matrix
       Functional connectivy matrix of the image. 
    """
        # Create masker to extract the timeseries
    masker = NiftiLabelsMasker(labels_img=atlas_filename, standardize=True)
    # if user is only inputing one module adapt input so is accepted by the function
    # define the connectome measure
    connectome_measure = ConnectivityMeasure(kind=measure)
    if isinstance(fmri_input,list):
        timeseries = []
        # loop that extracts the timeseries for each volume
        for i,volume in enumerate(fmri_input):
            if confounds_fn == "":
                timeseries.append(masker.fit_transform(volume).T)
            else:
                timeseries.append(masker.fit_transform(volume, confounds=confounds_fn[i]).T)
        timeseries = np.array(timeseries)
        final_ts = np.mean(timeseries,axis=0)
        # call fit_transform from ConnectivityMeasure object
    elif isinstance(fmri_input,str) or  hasattr(fmri_input,'affine'):
        final_ts = masker.fit_transform(fmri_input).T
    FC_matrix = connectome_measure.fit_transform([final_ts.T])[0]
    # saving each subject correlation to correlations
    return FC_matrix
