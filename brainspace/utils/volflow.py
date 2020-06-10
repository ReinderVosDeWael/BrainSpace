from nilearn import datasets
from nilearn.input_data import NiftiLabelsMasker
from nilearn.connectome import ConnectivityMeasure
import nibabel as nib
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


def grad2fmrivols(gradients, atlas, image_dim='4D'):
    """
    Takes computed gradient(s) from fitted GradientMaps object and converts them
    to 3D image(s) in volume format based on the atlas utilized in the GradientMaps
    object. The output can either be one 4D image where 3D gradients are concatenated
    or a list of 3D images, one per gradient.

    ----------
    gradients: array_like
        Fitted GradientMaps object.
    altas_filename: path or Nifti1Image
        Parcellation utilized within the computation of gradients, that is fmrivols2conn.
        Either name of the corresponding parcellation dataset or loaded dataset.
        Uses nilearn.datasets interface to fetch parcellation datasets and their information.
    image_dim: str
        Image dimensions of the Nifti1Image output. Either one 4D image where gradient
        maps are concatenated along the 4th dimension ('4D') or a list of 3D images, one per
        gradient ('3D'). Default is '4D'.
    Returns
    -------
    gradient_maps_vol: Nifti1Image
       4D image with gradient maps concatenated along the 4th dimension or list of 3D images, one
       per gradient.
    """

    #check if atlas_filename is str and thus should be loaded
    if isinstance(atlas, str):
        atlas_filename = eval('datasets.fetch_%s()' %atlas).maps
        atlas_img = nib.load(atlas_filename)
        atlas_data = atlas_img.get_fdata()
        labels = eval('datasets.fetch_%s()' %atlas).labels
    else:
    #read and define atlas data, affine and header
        atlas_img = atlas
        atlas_data = atlas.get_fdata()
        labels = atlas.labels

    gradient_list = []
    gradient_vols = []

    for gradient in range(gradients.n_components):

        gradient_list.append(np.zeros_like(atlas_data))

    for i, g in enumerate(gradient_list):
        for j in range(0, len(labels)):
            g[atlas_data == (j + 1)] = gradients.gradients_.T[i][j]
        gradient_vols.append(nib.Nifti1Image(g, atlas_img.affine, atlas_img.header))

    if image_dim is None or image_dim=='4D':
        gradient_vols = nib.concat_images(gradient_vols)
        print('Gradient maps will be concatenated within one 4D image.')
    elif image_dim=='3D':
        print('Gradient maps will be provided as a list of 3D images, one per gradient.')

    return gradient_vols