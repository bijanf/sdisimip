# (C) 2022 Potsdam Institute for Climate Impact Research (PIK)
# 
# This file is part of ISIMIP3BASD.
#
# ISIMIP3BASD is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the
# Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ISIMIP3BASD is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with ISIMIP3BASD. If not, see <http://www.gnu.org/licenses/>.



"""
Utility functions
=================

Provides auxiliary functions used by the modules bias_adjustment and
statistical_downscaling.

"""



import os
import warnings
import numpy as np
import datetime as dt
import scipy.stats as sps
import scipy.linalg as spl
import scipy.interpolate as spi
from pandas import Series
from netCDF4 import Dataset, default_fillvals
from cf_units import num2date
from itertools import product
from scipy.signal import convolve



def assert_uniform_number_of_doys(doys):
    """
    Raises an assertion error if the arrays in the input dict do not have the
    same number of unique elements. This is to make sure that a bias adjustment
    in running-window mode is feasible.

    Parameters
    ----------
    doys : dict of str : array
        Keys : 'obs_hist', 'sim_hist', 'sim_fut'.
        Values : day-of-year time series.

    """
    n_doys = None
    msg = 'input data do not cover the same days of the year'
    for key, d in doys.items():
        if n_doys is None: n_doys = np.unique(d).size
        else: assert n_doys == np.unique(d).size, msg



def assert_full_period_coverage(years, doys, key):
    """
    Raises an assertion error if the time axis described by the input arrays 
    has gaps or does not fully cover all years included. This is to make sure
    that a bias adjustment in running-window mode is feasible.

    Parameters
    ----------
    years : array
        Year time series.
    doys : array
        Day-of-year time series.
    key : str
        Key ('obs_hist', 'sim_hist', 'sim_fut') used for error messages.

    """
    # make sure years array is continuous
    years_sorted_unique = np.unique(years)
    ys = years_sorted_unique[0]
    ye = years_sorted_unique[-1]
    msg = f'not all years between {ys} and {ye} are covered in {key}'
    assert years_sorted_unique.size == ye - ys + 1, msg
    
    # prepare arrays of years and doys as they should be
    years_atsb = []
    doys_atsb = []
    for year in years_sorted_unique:
        n_days = (dt.date(year+1,1,1) - dt.date(year,1,1)).days
        years_atsb.append(np.repeat(year, n_days))
        doys_atsb.append(np.arange(1, n_days+1))
    years_atsb = np.concatenate(years_atsb)
    doys_atsb = np.concatenate(doys_atsb)

    # make sure all days from ys-01-01 to ye-12-31 are covered
    msg = f'not all days between {ys}-01-01 and {ye}-12-31 are covered in {key}'
    assert years.size == years_atsb.size and doys.size == doys_atsb.size, msg
    assert np.all(years == years_atsb) and np.all(doys == doys_atsb), msg




def assert_validity_of_step_size(step_size):
    """
    Raises an assertion error if step_size is not an uneven integer between 1
    and 31.

    Parameters
    ----------
    step_size : int
        Step size in number of days used for bias adjustment in running-window
        mode.

    """
    step_sizes_allowed = np.arange(1, 32, 2)
    msg = 'step_size has to be equal to 0 or an uneven integer between 1 and 31'
    assert step_size in step_sizes_allowed, msg



def assert_validity_of_months(months):
    """
    Raises an assertion error if any of the numbers in months is not in
    {1,...,12}.

    Parameters
    ----------
    months : array_like
        Sequence of ints representing calendar months.

    """
    months_allowed = np.arange(1, 13)
    for month in months:
        assert month in months_allowed, f'found {month} in months'



def assert_consistency_of_bounds_and_thresholds(
        lower_bound=None, lower_threshold=None,
        upper_bound=None, upper_threshold=None):
    """
    Raises an assertion error if the pattern of specified and
    unspecified bounds and thresholds is not valid or if
    lower_bound < lower_threshold < upper_threshold < upper_bound
    does not hold.

    Parameters
    ----------
    lower_bound : float, optional
        Lower bound of values in time series.
    lower_threshold : float, optional
        Lower threshold of values in time series. All values below this
        threshold will be replaced by random numbers between lower_bound and
        lower_threshold before bias adjustment.
    upper_bound : float, optional
        Upper bound of values in time series.
    upper_threshold : float, optional
        Upper threshold of values in time series. All values above this
        threshold will be replaced by random numbers between upper_threshold and
        upper_bound before bias adjustment.

    """
    lower = lower_bound is not None and lower_threshold is not None
    upper = upper_bound is not None and upper_threshold is not None

    if not lower:
       msg = 'lower_bound is not None and lower_threshold is None'
       assert lower_bound is None, msg
       msg = 'lower_bound is None and lower_threshold is not None'
       assert lower_threshold is None, msg
    if not upper:
       msg = 'upper_bound is not None and upper_threshold is None'
       assert upper_bound is None, msg
       msg = 'upper_bound is None and upper_threshold is not None'
       assert upper_threshold is None, msg

    if lower:
        assert lower_bound < lower_threshold, 'lower_bound >= lower_threshold'
    if upper:
        assert upper_bound > upper_threshold, 'upper_bound <= upper_threshold'
    if lower and upper:
        msg = 'lower_threshold >= upper_threshold'
        assert lower_threshold < upper_threshold, msg



def assert_consistency_of_distribution_and_bounds(
        distribution,
        lower_bound=None, lower_threshold=None,
        upper_bound=None, upper_threshold=None):
    """
    Raises an assertion error if the the distribution is not consistent with the
    pattern of specified and unspecified bounds and thresholds.

    Parameters
    ----------
    distribution : str
        Kind of distribution used for parametric quantile mapping:
        [None, 'normal', 'weibull', 'gamma', 'beta', 'rice'].
    lower_bound : float, optional
        Lower bound of values in time series.
    lower_threshold : float, optional
        Lower threshold of values in time series. All values below this
        threshold will be replaced by random numbers between lower_bound and
        lower_threshold before bias adjustment.
    upper_bound : float, optional
        Upper bound of values in time series.
    upper_threshold : float, optional
        Upper threshold of values in time series. All values above this
        threshold will be replaced by random numbers between upper_threshold and
        upper_bound before bias adjustment.

    """
    if distribution is not None:
        lower = lower_bound is not None and lower_threshold is not None
        upper = upper_bound is not None and upper_threshold is not None
    
        msg = distribution+' distribution '
        if distribution == 'normal':
            assert not lower and not upper, msg+'can not have bounds'
        elif distribution in ['weibull', 'gamma', 'rice']:
            assert lower and not upper, msg+'must only have lower bound'
        elif distribution == 'beta':
            assert lower and upper, msg+'must have lower and upper bound'
        else:
            raise AssertionError(msg+'not supported')



def assert_no_infs_or_nans(x_before, x_after):
    """
    Raises a value error if there are infs or nans in x_after. Prints the
    corresponding values in x_before.

    Parameters
    ----------
    x_before : ndarray
        Array before bias adjustement or statistical downscaling.
    x_after : ndarray
        Array after bias adjustement or statistical downscaling.

    """
    is_invalid = np.logical_or(np.isinf(x_after), np.isnan(x_after))
    if np.any(is_invalid):
        print(x_before[is_invalid])
        print(x_after[is_invalid], flush=True)
        msg = 'found infs or nans in x_after'
        raise ValueError(msg)



def ma2a(a, raise_error=False):
    """
    Turns masked array into array, replacing missing values and infs by nans.

    Parameters
    ----------
    a : array or masked array
        Array to convert.
    raise_error : boolean, optional
        Whether to raise an error if missing values, infs or nans are found.

    Returns
    -------
    b : array
        Data array.

    """
    b = np.ma.masked_invalid(a, copy=True)
    if np.any(b.mask):
        if raise_error:
            raise ValueError('found missing values, infs or nans in a')
        else:
            return b.filled(np.nan)
    else:
        return b.data



def analyze_input_nc(dataset, variable):
    """
    Returns coordinate variables associated with the given data variable in
    the given netcdf dataset, after making some assertions.

    Parameters
    ----------
    dataset : Dataset
        NetCDF dataset to analyze.
    variable : str
        Data variable to analyze.

    Returns
    -------
    coords : dict of str : array
        Keys : names of dimensions of data variable.
        Values : values of associated coordinate variables.

    """
    # there must be a variable in dataset with name variable
    dataset_variables = dataset.variables.keys()
    msg = f'could not find variable {variable} in nc file'
    assert variable in dataset_variables, msg

    # there must be coordinate variables for all dimensions of the data variable
    coords = {}
    for dim in dataset[variable].dimensions:
        msg = f'could not find variable {dim} in nc file'
        assert dim in dataset_variables, msg(dim)
        dd = dataset[dim]
        msg = f'variable {dim} should have dimensions ({dim},)'
        assert dd.dimensions == (dim,), msg
        coords[dim] = ma2a(dd[:], True)

    # time must be the last dimension
    assert coords and dim == 'time', 'time must be last dimension'

    # the proleptic gregorian calendar must be used
    msg = 'calendar must be proleptic_gregorian'
    assert 'calendar' in dd.ncattrs(), msg
    assert dd.getncattr('calendar') == 'proleptic_gregorian', msg

    # convert time coordinate values to datetime objects
    coords[dim] = num2date(list(coords[dim]), dd.units, dd.calendar)

    return coords



def grid_cell_weights(coords):
    """
    Computes grid cell weights based on grid cell area, assuming a regular
    latitude-longitude grid.

    Parameters
    ----------
    coords : dict of str : array
        Keys : names of dimensions of data variable.
        Values : values of associated coordinate variables.

    Returns
    -------
    weights : ndarray
        Grid cell weights with shape according to lengths of spatial coordinate
        variables.

    """
    weights_shape = tuple(v.size for k, v in coords.items() if k != 'time')
    weights = np.empty(weights_shape, dtype=np.float32)
    lat_names_potential = ['lat', 'latitude', 'rlat']
    lat_names = [s for s in lat_names_potential if s in coords]
    if len(lat_names) == 0:
        msg = (f'found none of {lat_names_potential} in coords,'
                ' will hence work with uniform grid cell weights')
        warnings.warn(msg)
        weights[:] = 1
    elif len(lat_names) == 1:
        lats = coords[lat_names[0]]
        msg = f'found {lat_names[0]} values outside [-90, 90]'
        assert np.all(lats <= 90) and np.all(lats >= -90), msg
        i = list(coords.keys()).index(lat_names[0])
        shape = (1,) * i + lats.shape + (1,) * (len(weights_shape) - 1 - i)
        weights[:] = np.cos(np.deg2rad(lats)).reshape(shape)
    else:
        msg = f'found more than one of {lat_names_potential} in coords'
        raise ValueError(msg)
    return weights



def analyze_input_grids(coords_coarse, coords_fine):
    """
    Makes sure that the coarse and fine grids meet the requirements of the
    downscaling algorithm. Returns information about the grids if they do.

    Parameters
    ----------
    coords_coarse : list of arrays
        Values of spatial coordinate variables of coarse grid.
    coords_fine : list of arrays
        Values of spatial coordinate variables of fine grid.

    Returns
    -------
    downscaling_factors : array of ints
        Downscaling factors for all dimensions.
    ascending : tuple of booleans
        Whether coordinates are monotonically increasing.
    circular : tuple of booleans
        Whether coordinates are circular.

    """
    downscaling_factors = []
    ascending = []
    circular = []

    # loop over dimensions
    for i, x in enumerate(coords_coarse):
        y = coords_fine[i]

        # analyze dimension length
        msg = f'grid size issue in spatial dimension {i}'
        assert len(x) > 1, msg

        # analyze downscaling factor
        msg = f'downscaling factor issue in spatial dimension {i}'
        assert len(y) % len(x) == 0, msg
        f = len(y) // len(x)
        assert f > 1, msg
        downscaling_factors.append(f)

        # analyze invertedness
        dx, dy = np.diff(x), np.diff(y)
        msg = f'monotonicity issue in spatial dimension {i}'
        assert (np.all(dx > 0) and np.all(dy > 0) or
                np.all(dx < 0) and np.all(dy < 0)), msg
        a = dx[0] > 0
        ascending.append(a)

        # analyze circularness
        three_sixty = 360 if a else -360
        circular.append(np.allclose(x[:1] - dx[:1] + three_sixty, x[-1]))

        # ensure uniform spacing of fine grid cells in every large grid cell
        d = np.delete(dy, np.arange(f-1, dy.size, f)).reshape(f-1, len(x))
        msg = f'uniform spacing issue in spatial dimension {i}'
        for j in range(f-2):
            assert np.allclose(d[:,j], d[:,j+1]), msg

        # compute expected y and compare to y
        s = .5 * (np.concatenate((dx[:1], dx)) + np.concatenate((dx, dx[-1:])))
        t = np.arange(1, f + 1) / f
        y_delta = np.repeat(s, f) * np.tile(t - .5 * t[0], x.size)
        y_expected = np.repeat(x - .5 * s, f) + y_delta
        msg = f'expected coordinate issue in spatial dimension {i}'
        assert np.allclose(y, y_expected), msg

    return np.array(downscaling_factors), tuple(ascending), tuple(circular)



def split(s, n=None, converter=str, empty=None, delimiter=','):
    """
    Splits string s into a list of strings using the specified delimiter,
    replaces empty strings in the resulting list by empty, and applies the
    specified converter to all other values in the resulting list.

    If the split of s results in a list of length 1 and n > 1 then s is repeated
    to obtain a list of length n. Otherwise the split of s is asserted to result
    in a list of length n.

    Parameters
    ----------
    s : str
        String to be split.
    n : int, optional
        Target list length.
    converter : function, optional
        Function to change the data type of the list elements
    empty : any type, optional
        Value that empty list elements are mapped to.
    delimiter : str, optional
        Delimiter used to split s.

    Returns
    -------
    l : list
        Resulting list.

    """
    l = s.split(delimiter)
    if isinstance(n, int):
        m = len(l)
        if m == 1 and n > 1:
            l = [s for i in range(n)]
        else:
            msg = 'list length = %i != %i'%(m, n)
            assert m == n, msg
    return [empty if s == '' else converter(s) for s in l]



def setup_output_nc(
        dst_path, src, var,
        basd_options, basd_prefix='', basd_index=None, src_fine=None):
    """
    Creates output netcdf file of bias adjustment or statistical downscaling.
    Copies information from src and (in the case of statistical downsacling)
    src_fine. An empty data variable is created, so local bias adjustment or
    statistical downscaling results can be added later. The basd_* parameters
    are used to store bias adjustment or statistical downscaling information
    in the global attributes of the output file.

    Parameters
    ----------
    dst_path : str
        Path to output file.
    src : Dataset
        Input dataset; coarse resolution dataset in the case of statistical
        downsacling.
    var : str
        Name of data variable.
    basd_options : optparse.Values
        Command line options parsed by optparse.OptionParser.
    basd_prefix : str, optional
        Prefix to be added to all global BASD attributes.
    basd_index : int, optional
        If provided then only save the options relevant for the variable with
        the given index.
    src_fine : Dataset, optional
        For statistical downscaling only; fine resolution dataset used to set
        spatial dimensions and coordinate variables of output file.

    """
    # make sure output directory exists
    dst_dir = os.path.dirname(dst_path)
    if dst_dir and not os.path.exists(dst_dir):
        os.makedirs(dst_dir, exist_ok=True)

    # create output netcdf file
    with Dataset(dst_path, 'w') as dst:
        # copy global attributes, adding BASD attributes
        global_attributes = src.__dict__
        global_attributes[basd_prefix+'version'] = 'ISIMIP3BASD v3.0.1'
        for key, value in basd_options.__dict__.items():
            if basd_index and key != 'months' and isinstance(value, str):
                v = value.split(',')[basd_index] if ',' in value else value
            else:
                v = value
            global_attributes[basd_prefix+key] = str(v)
        dst.setncatts(global_attributes)

        # copy dimensions, using spatial dimensions from src_fine
        dim_fine = () if src_fine is None else src[var].dimensions[:-1]
        for name, dimension in src.dimensions.items():
            # copy spatial dimensions from src_fine
            if name in dim_fine:
                dimension = src_fine.dimensions[name]
            dst.createDimension(name, len(dimension))

        # copy variables, including variable attributes
        for name, variable in src.variables.items():
            # copy spatial coordinate variables from src_fine
            if dim_fine and (name == var or
                all(d in dim_fine for d in variable.dimensions)):
                variable = src_fine[name]
            # determine fill value
            variable_attributes = src[name].__dict__
            fv = variable_attributes.pop('missing_value', None)
            fv = variable_attributes.pop('_FillValue', fv)
            if fv is None and name == var:
                dts = variable.datatype.str[1:]
                assert dts in default_fillvals, 'unable to set fill_value'
                fv = default_fillvals[dts]
            # determine chunking
            c = variable.chunking()
            if dim_fine and name == var and c != 'contiguous':
                c[-1] = src[name].chunking()[-1]
            # create variable
            dst.createVariable(name, variable.datatype, variable.dimensions,
                chunksizes=None if c == 'contiguous' else c, fill_value=fv)
            # copy attributes except missing_value and _FillValue
            dst[name].setncatts(variable_attributes)
            # copy data for all coordinate variables
            if name != var:
                dst[name][:] = variable[:]



def extended_load(nc_variable, i_loc, space_shape, circular):
    """
    Loads data from nc_variable for grid window of width 3 by 3 by 3 by ...
    around i_loc. Data beyond the grid boundaries, defined by space_shape, are
    set to nan unless circular indicates that for a given dimension data from
    the other end of the grid can be used. Missing values and infs in the input
    data are replaced by nans.

    Parameters
    ----------
    nc_variable : Dataset.variable
        Variable of netcdf dataset from which to load.
    i_loc : n-tuple of ints
        Index around which to do the extended load.
    space_shape : n-tuple of ints
        Shape of grid from which to do the extended load.
    circular : n-tuple of booleans
        Whether coordinates are circular.

    Returns
    -------
    x : masked array
        Original data at i_loc.
    x_extended : ndarray
        Data for grid window of width 3 by 3 by 3 by ...

    """
    ndim = len(i_loc)
    msg = 'input tuples must have uniform length'
    assert ndim == len(space_shape) == len(circular), msg
    x = nc_variable[i_loc]
    x_extended_space_shape = (3,) * ndim
    x_extended = np.empty(x_extended_space_shape + x.shape, dtype=x.dtype)
    for i in np.ndindex(x_extended_space_shape):
        j_raw = np.array(i_loc) + np.array(i) - 1
        j = np.where(circular, j_raw % np.array(space_shape), j_raw)
        if np.any(j < 0) or np.any(j > np.array(space_shape) - 1):
            x_extended[i] = np.nan
        else:
            x_extended[i] = ma2a(nc_variable[tuple(j)])
    return x, x_extended



def xipm1(x, i):
    """
    Extract points from x at position i +- 1, linearly extrapolating beyond
    the limits of x.

    Parameters
    ----------
    x : array
        Array from which to do the extraction.
    i : int
        Index around which to do the extraction.

    Returns
    -------
    y : array
        Extracted points.

    """
    n = x.size
    assert n > 1, 'x too short'
    y0 = 2 * x[0] - x[1] if i == 0 else x[i-1]
    y1 = x[i]
    y2 = 2 * x[-1] - x[-2] if i == n - 1 else x[i+1]
    y = np.array([y0, y1, y2])
    return y



def remapbil(ivalues, igrid, ogrid, ascending):
    """
    Remaps ivalues from igrid to ogrid using multilinear interpolation on a
    regular grid in arbitrary dimensions. NaNs resulting from the interpolation
    are replaced by ivalues from the central grid cell of igrid, with the
    following background. Where multilinear interpolation is not possible due to
    missing values in neighbouring coarse grid cells, values obtained with
    nearest neighbour interpolation are filled in. In the end, every fine grid
    cell fully contained in a coarse grid cell with available data should also
    have available data.

    This code was inspired by scipy.interpolate.RegularGridInterpolator.

    Parameters
    ----------
    ivalues : ndarray
        Values on input grid. This ndarray can have more dimensions than igrid,
        ogrid, and ascending. If this is the case then remapping is broadcasted
        to the additional, trailing dimensions.
    igrid : list of arrays
        Input grid coordinates. It is expected that all arrays have length 3.
    ogrid : list of arrays
        Output grid coordinates.
    ascending : tuple of booleans
        A tuple of the same length as igrid and ogrid. For every dimension, it
        specifies whether the coordinates in igrid are monotonically increasing
        (True) or decreasing (False).

    Returns
    -------
    ovalues : ndarray
        Interpolated values on output grid.

    """
    # find lower edge of every point in ogrid
    indices = []
    # compute distance to lower edge in unity units
    norm_distances = []
    # lower edge index functions
    i_ascending = lambda x, y: np.searchsorted(y, x) - 1
    i_descending = lambda x, y: y.size - 1 - np.searchsorted(
        y, x, 'right', np.arange(y.size - 1,-1,-1))
    # loop over dimensions
    for a, x, y in zip(ascending, ogrid, igrid):
        i = i_ascending(x, y) if a else i_descending(x, y)
        indices.append(i)
        norm_distances.append((x - y[i]) / (y[i + 1] - y[i]))

    # interpolate using weights
    ndim = len(igrid)
    ndim_trailing = ivalues.ndim - ndim
    wshape_trailing = (2,) * ndim + (1,) * ndim_trailing
    gshape = tuple(len(grid) for grid in ogrid)
    oshape = gshape + ivalues.shape[ndim:]
    ovalues = np.empty(oshape, dtype=ivalues.dtype)
    # loop over interpolation points
    for oind in np.ndindex(gshape):
        weights = np.ones((2,)*ndim, dtype=ivalues.dtype)
        # each i and i+1 represents a edge
        edges = tuple(np.array([index[oind[i]], index[oind[i]]+1])
            for i, index in enumerate(indices))
        # loop over dimensions
        for i, edge in enumerate(edges):
            index = indices[i][oind[i]]
            w = norm_distances[i][oind[i]]
            wshape = (1,) * i + (2,) + (1,) * (ndim - 1 - i)
            weights *= np.where(edge == index, 1 - w, w).reshape(wshape)
        result = np.sum(
            ivalues[np.ix_(*edges)] * weights.reshape(wshape_trailing),
            axis=tuple(np.arange(ndim))
        )
        # replace nans by ivalues from central grid cell of igrid
        i_nan = np.isnan(result)
        result[i_nan] = ivalues[(1,) * ndim][i_nan]
        ovalues[oind] = result

    return ovalues



def window_centers_for_running_bias_adjustment(doys, step_size):
    """
    Returns window centers for bias adjustment in running-window mode.

    Parameters
    ----------
    doys : array
        Day-of-year time series of historical input data.
    step_size : int
        Step size in number of days used for bias adjustment in running-window
        mode.

    Returns
    -------
    doys_center : array
        Window centers for bias adjustment in running-window mode. In 
        day-of-year units.

    """
    doy_max = np.max(doys)
    doy_mod = doy_max % step_size
    doys_center_first = 1 + step_size // 2
    # make sure first and last window have the same length +- 1
    if doy_mod: doys_center_first -= (step_size - doy_mod) // 2
    doys_center = np.arange(doys_center_first, doy_max+1, step_size)
    return doys_center



def window_indices_for_running_bias_adjustment(
        doys, window_center, window_width, years=None):
    """
    Returns window indices for data selection for bias adjustment in
    running-window mode.

    Parameters
    ----------
    doys : array
        Day-of-year time series associated to data array from which data shall
        be selected using the resulting indices.
    window_center : int
        Day of year at the center of each window.
    window_width : int
        Width of each window in days.
    years : array, optional
        Year time series associated to data array from which data shall
        be selected using the resulting indices. If provided, it is ensured
        that windows do not extend into the following or previous year.

    Returns
    -------
    i_window : array
        Window indices.

    """
    i_center = np.where(doys == 365)[0] + 1 \
               if window_center == 366 else \
               np.where(doys == window_center)[0]
    h = window_width // 2
    if years is None:
        i_window = np.concatenate([np.arange(i-h, i+h+1) for i in i_center])
        i_window = np.sort(np.mod(i_window, doys.size))
    else:
        years_unique = np.unique(years)
        if years_unique.size == 1: 
            # time series only covers one year
            i = i_center[0]
            i_window = np.mod(np.arange(i-h, i+h+1), doys.size)
            i_window = i_window[i_window == np.arange(i-h, i+h+1)]
        else:
            # time series covers multiple years
            i_window_list = []
            for j, i in enumerate(i_center):
                i_this_window = np.mod(np.arange(i-h, i+h+1), doys.size)
                y_this_window = years[i_this_window]
                i_this_window = i_this_window[y_this_window == years_unique[j]]
                i_window_list.append(i_this_window)
            i_window = np.concatenate(i_window_list)
    return i_window



def aggregate_periodic(a, halfwin, aggregator='mean'):
    """
    Aggregates a using the given aggregator and a running window of length
    2 * halfwin + 1 assuming that a is periodic.

    Parameters
    ----------
    a : array
        Array to be aggregated.
    halfwin : int
        Determines length of running window used for aggregation.
    aggregator : str, optional
        Determines how a is aggregated along axis 0 for every running window.

    Returns
    -------
    rm : ndarray
        Result of aggregation. Same shape as a.

    """
    assert halfwin >= 0, 'halfwin < 0'
    if not halfwin: return a

    # extend a periodically
    n = a.size
    assert n >= halfwin, 'length of a along axis 0 less than halfwin'
    b = np.concatenate((a[-halfwin:], a, a[:halfwin]))

    # aggregate using algorithm for max inspired by
    # <http://p-nand-q.com/python/algorithms/searching/max-sliding-window.html>
    window = 2 * halfwin + 1
    if aggregator == 'max':
        c = list(np.maximum.accumulate(b[:window][::-1]))
        rm = np.empty_like(a)
        rm[0] = c[-1]
        for i in range(n-1):
            c_new = b[i+window]
            del c[-1]
            for j in range(window-1):
                if c_new > c[j]: c[j] = c_new
                else: break
            c.insert(0, c_new)
            rm[i+1] = c[-1]
    elif aggregator == 'mean':
        rm = convolve(b, np.repeat(1./window, window), 'valid')
    else:
        raise ValueError(f'aggregator {aggregator} not supported')

    return rm



def get_upper_bound_climatology(d, doys, halfwin):
    """
    Estimates an annual cycle of upper bounds as running mean values of running
    maximum values of multi-year daily maximum values.

    Parameters
    ----------
    d : array
        Time series for which annual cycles of upper bounds shall be estimated.
    doys : array
        Day of the year time series corresponding to d.
    halfwin : int
        Determines length of running windows used for estimation.

    Returns
    -------
    ubc : array
        Upper bound climatology.
    doys_unique : array
        Days of the year of upper bound climatology.

    """
    assert d.shape == doys.shape, 'd and doys differ in shape' 

    # check length of time axis of resulting array
    doys_unique, counts = np.unique(doys, return_counts=True)
    n = doys_unique.size
    if n != 366:
        msg = (f'upper bound climatology only defined for {n} days of the year:'
                ' this may imply an invalid computation of the climatology')
        warnings.warn(msg)

    # compute multi year daily maximum
    d_sorted = d[np.argsort(doys)]
    mydm = np.empty(n, dtype=d.dtype)
    if np.unique(counts[:-1]).size == 1:
        # fast version which applies in the usual case
        if counts[0] == counts[-1]:
            d_stacked = d_sorted.reshape(n, counts[0])
            mydm = np.max(d_stacked, axis=1) 
        else:
            mydm[-1] =  np.max(d_sorted[-counts[-1]:])
            d_stacked = d_sorted[:-counts[-1]].reshape(n-1, counts[0])
            mydm[:-1] = np.max(d_stacked, axis=1) 
    else:
        # slow version which always works
        j = 0
        for i in range(n):
            k = j + counts[i]
            mydm[i] = np.max(d_sorted[j:k])
            j = k

    # smooth multi year daily maximum
    mydmrm = aggregate_periodic(mydm, halfwin, aggregator='max')
    ubc = aggregate_periodic(mydmrm, halfwin, aggregator='mean')

    return ubc, doys_unique



def ccs_transfer_sim2obs_upper_bound_climatology(obs_hist, sim_hist, sim_fut):
    """
    Multiplicatively transfers simulated climate change signal from sim_hist,
    sim_fut to obs_hist.

    Parameters
    ----------
    obs_hist : array
        Upper bound climatology of observed climate data representing the
        historical or training time period.
    sim_hist : array
        Upper bound climatology of simulated climate data representing the
        historical or training time period.
    sim_fut : array
        Upper bound climatology of simulated climate data representing the
        future or application time period.

    Returns
    -------
    sim_fut_ba : array
        Result of climate change signal transfer.

    """
    assert obs_hist.shape == sim_hist.shape == sim_fut.shape, \
        'obs_hist, sim_hist, sim_fut differ in shape'
    with np.errstate(divide='ignore', invalid='ignore'):
        change_factor = np.where(sim_hist == 0, 1, sim_fut / sim_hist)
    change_factor = np.maximum(.1, np.minimum(10., change_factor))
    sim_fut_ba = obs_hist * change_factor
    return sim_fut_ba



def scale_by_upper_bound_climatology(
        d, ubc, d_doys, ubc_doys, divide=True):
    """
    Scales all values in d using the annual cycle of upper bounds.

    Parameters
    ----------
    d : array
        Time series to be scaled. Is changed in-place.
    ubc : array
        Upper bound climatology used for scaling.
    d_doys : array
        Days of the year corresponding to d.
    ubc_doys : array
        Days of the year corresponding to ubc.
    divide : boolean, optional
        If True then d is divided by upper_bound_climatology, otherwise they
        are multiplied.

    """
    assert d.shape == d_doys.shape, 'd and d_doys differ in shape' 
    assert ubc.shape == ubc_doys.shape, 'ubc and ubc_doys differ in shape' 

    if divide:
        with np.errstate(divide='ignore', invalid='ignore'):
            scaling_factors = np.where(ubc == 0, 1., 1./ubc)
    else:
        scaling_factors = ubc

    # use fast solution if ubc covers all days of the year
    # this fast solution assumes that ubc_doys is sorted
    scaling_factors_broadcasted = scaling_factors[d_doys-1] \
        if ubc.size == 366 else \
        np.array([scaling_factors[ubc_doys == doy][0] for doy in d_doys])

    d *= scaling_factors_broadcasted

    # make sure d does not exceed the upper bound climatology
    if not divide:
        d_too_large = d > scaling_factors_broadcasted
        n = np.sum(d_too_large)
        msg = f'capping {n} values exceeding the upper bound climatology'
        if n:
            warnings.warn(msg)
            d[d_too_large] = scaling_factors_broadcasted[d_too_large]



def subtract_or_add_trend(x, years, trend=None):
    """
    Subtracts or adds trend from or to x.

    Parameters
    ----------
    x : array
        Time series.
    years : array
        Years of time points of x used to subtract or add trend at annual
        temporal resolution.
    trend : array, optional
        Trend line. If provided then this is the trend line added to x.
        Otherwise, a trend line is computed and subtracted from x

    Returns
    -------
    y : array
        Result of trend subtraction or addition from or to x.
    trend : array, optional
        Trend line. Is only returned if the parameter trend is None.

    """
    assert x.size == years.size, 'size of x != size of years'
    unique_years = np.unique(years)

    # compute trend
    if trend is None:
        annual_means = np.array([np.mean(x[years == y]) for y in unique_years])
        r = sps.linregress(unique_years, annual_means)
        if r.pvalue < .05:  # detrend preserving multi-year mean value
            trend = r.slope * (unique_years - np.mean(unique_years))
        else:  # do not detrend because trend is insignificant
            trend = np.zeros(unique_years.size, dtype=x.dtype)
        return_trend = True
    else:
        msg = 'size of trend array != number of unique years'
        assert trend.size == unique_years.size, msg
        trend = -trend
        return_trend = False

    # subtract or add trend
    if np.any(trend):
        y = np.empty_like(x)
        for i, year in enumerate(unique_years):
            is_year = years == year
            y[is_year] = x[is_year] - trend[i]
    else:
        y = x.copy()

    # return result(s)
    if return_trend:
        return y, trend
    else:
        return y



def percentile1d(a, p):
    """
    Fast version of np.percentile with linear interpolation for 1d arrays
    inspired by
    <https://krstn.eu/np.nanpercentile()-there-has-to-be-a-faster-way/>.

    Parameters
    ----------
    a : array
        Input array.
    p : array
        Percentages expressed as real numbers in [0, 1] for which percentiles
        are computed.

    Returns
    -------
    percentiles : array
        Percentiles

    """
    n = a.size - 1
    b = np.sort(a)
    i = n * p
    i_below = np.floor(i).astype(int)
    w_above = i - i_below
    return b[i_below] * (1. - w_above) + b[i_below + (i_below < n)] * w_above



def map_quantiles_non_parametric_trend_preserving(
        x_obs_hist, x_sim_hist, x_sim_fut, 
        trend_preservation='additive', n_quantiles=50,
        max_change_factor=100., max_adjustment_factor=9.,
        adjust_obs=False, lower_bound=None, upper_bound=None):
    """
    Adjusts biases with a modified version of the quantile delta mapping by
    Cannon (2015) <https://doi.org/10.1175/JCLI-D-14-00754.1> or uses this
    method to transfer a simulated climate change signal to observations.

    Parameters
    ----------
    x_obs_hist : array
        Time series of observed climate data representing the historical or
        training time period.
    x_sim_hist : array
        Time series of simulated climate data representing the historical or
        training time period.
    x_sim_fut : array
        Time series of simulated climate data representing the future or
        application time period.
    trend_preservation : str, optional
        Kind of trend preservation:
        'additive'       # Preserve additive trend.
        'multiplicative' # Preserve multiplicative trend, ensuring
                         # 1/max_change_factor <= change factor
                         #                     <= max_change_factor.
        'mixed'          # Preserve multiplicative or additive trend or mix of
                         # both depending on sign and magnitude of bias. Purely
                         # additive trends are preserved if adjustment factors
                         # of a multiplicative adjustment would be greater then
                         # max_adjustment_factor.
        'bounded'        # Preserve trend of bounded variable. Requires
                         # specification of lower_bound and upper_bound. It is
                         # ensured that the resulting values stay within these
                         # bounds.
    n_quantiles : int, optional
        Number of quantile-quantile pairs used for non-parametric quantile
        mapping.
    max_change_factor : float, optional
        Maximum change factor applied in non-parametric quantile mapping with
        multiplicative or mixed trend preservation.
    max_adjustment_factor : float, optional
        Maximum adjustment factor applied in non-parametric quantile mapping
        with mixed trend preservation.
    adjust_obs : boolean, optional
        If True then transfer simulated climate change signal to x_obs_hist,
        otherwise apply non-parametric quantile mapping to x_sim_fut.
    lower_bound : float, optional
        Lower bound of values in x_obs_hist, x_sim_hist, and x_sim_fut. Used
        for bounded trend preservation.
    upper_bound : float, optional
        Upper bound of values in x_obs_hist, x_sim_hist, and x_sim_fut. Used
        for bounded trend preservation.

    Returns
    -------
    y : array
        Result of quantile mapping or climate change signal transfer.

    """
    # make sure there are enough input data for quantile delta mapping
    # reduce n_quantiles if necessary
    assert n_quantiles > 0, 'n_quantiles <= 0'
    n = min([n_quantiles + 1, x_obs_hist.size, x_sim_hist.size, x_sim_fut.size])
    if n < 2:
        if adjust_obs:
            msg = 'not enough input data: returning x_obs_hist'
            y = x_obs_hist
        else:
            msg = 'not enough input data: returning x_sim_fut'
            y = x_sim_fut
        warnings.warn(msg)
        return y
    elif n < n_quantiles + 1:
        msg = 'due to little input data: reducing n_quantiles to %i'%(n-1)
        warnings.warn(msg)
    p_zeroone = np.linspace(0., 1., n)

    # compute quantiles of input data
    q_obs_hist = percentile1d(x_obs_hist, p_zeroone)
    q_sim_hist = percentile1d(x_sim_hist, p_zeroone)
    q_sim_fut = percentile1d(x_sim_fut, p_zeroone)

    # compute quantiles needed for quantile delta mapping
    if adjust_obs: p = np.interp(x_obs_hist, q_obs_hist, p_zeroone)
    else: p = np.interp(x_sim_fut, q_sim_fut, p_zeroone)
    F_sim_fut_inv  = np.interp(p, p_zeroone, q_sim_fut)
    F_sim_hist_inv = np.interp(p, p_zeroone, q_sim_hist)
    F_obs_hist_inv = np.interp(p, p_zeroone, q_obs_hist)

    # do augmented quantile delta mapping
    if trend_preservation == 'bounded':
        msg = 'lower_bound or upper_bound not specified'
        assert lower_bound is not None and upper_bound is not None, msg
        assert lower_bound < upper_bound, 'lower_bound >= upper_bound'
        y = ccs_transfer_sim2obs(
            F_obs_hist_inv, F_sim_hist_inv, F_sim_fut_inv,
            lower_bound, upper_bound)
    elif trend_preservation in ['mixed', 'multiplicative']:
        assert max_change_factor > 1, 'max_change_factor <= 1'
        with np.errstate(divide='ignore', invalid='ignore'):
            y = np.where(F_sim_hist_inv == 0, 1., F_sim_fut_inv/F_sim_hist_inv)
            y[y > max_change_factor] = max_change_factor
            y[y < 1. / max_change_factor] = 1. / max_change_factor
        y *= F_obs_hist_inv
        if trend_preservation == 'mixed':  # if not then we are done here
            assert max_adjustment_factor > 1, 'max_adjustment_factor <= 1'
            y_additive = F_obs_hist_inv + F_sim_fut_inv - F_sim_hist_inv
            fraction_multiplicative = np.zeros_like(y)
            fraction_multiplicative[F_sim_hist_inv >= F_obs_hist_inv] = 1.
            i_transition = np.logical_and(F_sim_hist_inv < F_obs_hist_inv,
                F_obs_hist_inv < max_adjustment_factor * F_sim_hist_inv)
            fraction_multiplicative[i_transition] = .5 * (1. + 
                np.cos((F_obs_hist_inv[i_transition] /
                F_sim_hist_inv[i_transition] - 1.) * 
                np.pi / (max_adjustment_factor - 1.)))
            y = fraction_multiplicative * y + (1. -
                fraction_multiplicative) * y_additive
    elif trend_preservation == 'additive':
        y = F_obs_hist_inv + F_sim_fut_inv - F_sim_hist_inv
    else:
        msg = 'trend_preservation = '+trend_preservation+' not supported'
        raise AssertionError(msg)

    return y



def map_quantiles_non_parametric_with_constant_extrapolation(x, q_sim, q_obs):
    """
    Uses quantile-quantile pairs represented by values in q_sim and q_obs
    for quantile mapping of x.

    Values in x beyond the range of q_sim are mapped following the constant
    extrapolation approach, see Boe et al. (2007)
    <https://doi.org/10.1002/joc.1602>.

    Parameters
    ----------
    x : array
        Simulated time series.
    q_sim : array
        Simulated quantiles.
    q_obs : array
        Observed quantiles.
    
    Returns
    -------
    y : array
        Result of quantile mapping.

    """
    assert q_sim.size == q_obs.size
    lunder = x < q_sim[0]
    lover = x > q_sim[-1]
    y = np.interp(x, q_sim, q_obs)
    y[lunder] = x[lunder] + (q_obs[0] - q_sim[0])
    y[lover] = x[lover] + (q_obs[-1] - q_sim[-1])
    return y



def map_quantiles_non_parametric_brute_force(x, y):
    """
    Quantile-map x to y using the empirical CDFs of x and y.

    Parameters
    ----------
    x : array
        Simulated time series.
    y : array
        Observed time series.
    
    Returns
    -------
    z : array
        Result of quantile mapping.

    """
    if x.size == 0:
        msg = 'found no values in x: returning x'
        warnings.warn(msg)
        return x

    if np.unique(y).size < 2:
        msg = 'found fewer then 2 different values in y: returning x'
        warnings.warn(msg)
        return x

    p_x = (sps.rankdata(x) - 1.) / x.size  # percent points of x
    p_y = np.linspace(0., 1., y.size)  # percent points of sorted y
    z = np.interp(p_x, p_y, np.sort(y))  # quantile mapping
    return z



def ccs_transfer_sim2obs(
        x_obs_hist, x_sim_hist, x_sim_fut,
        lower_bound=0., upper_bound=1.):
    """
    Generates pseudo future observation(s) by transfering a simulated climate
    change signal to historical observation(s) respecting the given bounds.

    Parameters
    ----------
    x_obs_hist : float or array
        Historical observation(s).
    x_sim_hist : float or array
        Historical simulation(s).
    x_sim_fut : float or array
        Future simulation(s).
    lower_bound : float, optional
        Lower bound of values in input and output data.
    upper_bound : float, optional
        Upper bound of values in input and output data.
    
    Returns
    -------
    x_obs_fut : float or array
        Pseudo future observation(s).

    """
    # change scalar inputs to arrays
    if np.isscalar(x_obs_hist): x_obs_hist = np.array([x_obs_hist])
    if np.isscalar(x_sim_hist): x_sim_hist = np.array([x_sim_hist])
    if np.isscalar(x_sim_fut): x_sim_fut = np.array([x_sim_fut])

    # check input
    assert lower_bound < upper_bound, 'lower_bound >= upper_bound'
    for x_name, x in zip(['x_obs_hist', 'x_sim_hist', 'x_sim_fut'],
                         [x_obs_hist, x_sim_hist, x_sim_fut]):
        assert np.all(x >= lower_bound), 'found '+x_name+' < lower_bound'
        assert np.all(x <= upper_bound), 'found '+x_name+' > upper_bound'

    # compute x_obs_fut
    i_neg_bias = x_sim_hist < x_obs_hist
    i_zero_bias = x_sim_hist == x_obs_hist
    i_pos_bias = x_sim_hist > x_obs_hist
    i_additive = np.logical_or(
        np.logical_and(i_neg_bias, x_sim_fut < x_sim_hist),
        np.logical_and(i_pos_bias, x_sim_fut > x_sim_hist))
    x_obs_fut = np.empty_like(x_obs_hist)
    x_obs_fut[i_neg_bias] = upper_bound - \
                            (upper_bound - x_obs_hist[i_neg_bias]) * \
                            (upper_bound - x_sim_fut[i_neg_bias]) / \
                            (upper_bound - x_sim_hist[i_neg_bias])
    x_obs_fut[i_zero_bias] = x_sim_fut[i_zero_bias]
    x_obs_fut[i_pos_bias] = lower_bound + \
                            (x_obs_hist[i_pos_bias] - lower_bound) * \
                            (x_sim_fut[i_pos_bias] - lower_bound) / \
                            (x_sim_hist[i_pos_bias] - lower_bound)
    x_obs_fut[i_additive] = x_obs_hist[i_additive] + \
                            x_sim_fut[i_additive] - x_sim_hist[i_additive]

    # make sure x_obs_fut is within bounds
    x_obs_fut = np.maximum(lower_bound, np.minimum(upper_bound, x_obs_fut))

    return x_obs_fut[0] if x_obs_fut.size == 1 else x_obs_fut



def transfer_odds_ratio(p_obs_hist, p_sim_hist, p_sim_fut):
    """
    Transfers simulated changes in event likelihood to historical observations
    by multiplying the historical odds by simulated future-over-historical odds
    ratio. The method is inspired by the return interval scaling proposed by
    Switanek et al. (2017) <https://doi.org/10.5194/hess-21-2649-2017>.

    Parameters
    ----------
    p_obs_hist : array
        Culmulative probabbilities of historical observations.
    p_sim_hist : array
        Culmulative probabbilities of historical simulations.
    p_sim_fut : array
        Culmulative probabbilities of future simulations.

    Returns
    -------
    p_obs_fut : array
        Culmulative probabbilities of pseudo future observations.

    """
    x = np.sort(p_obs_hist)
    y = np.sort(p_sim_hist)
    z = np.sort(p_sim_fut)

    # interpolate x and y if necessary
    if x.size != z.size or y.size != z.size:
        p_x = np.linspace(0, 1, x.size)
        p_y = np.linspace(0, 1, y.size)
        p_z = np.linspace(0, 1, z.size)
        ppf_x = spi.interp1d(p_x, x)
        ppf_y = spi.interp1d(p_y, y)
        x = ppf_x(p_z)
        y = ppf_y(p_z)

    # transfer
    A = x * (1. - y) * z
    B = (1. - x) * y * (1. - z)
    z_scaled = 1. / (1. + B / A)

    # avoid the generation of unrealistically extreme p-values
    z_min = 1. / (1. + np.power(10.,  1. - np.log10(x / (1. - x))))
    z_max = 1. / (1. + np.power(10., -1. - np.log10(x / (1. - x))))
    z_scaled = np.maximum(z_min, np.minimum(z_max, z_scaled))

    return z_scaled[np.argsort(np.argsort(p_sim_fut))]



def randomize_censored_values_core(y, bound, threshold, inverse, power, lower):
    """
    Randomizes values beyond threshold in y or de-randomizes such formerly
    randomized values. Note that y is changed in-place. The randomization
    algorithm is inspired by <https://stackoverflow.com/questions/47429845/
    rank-with-ties-in-python-when-tie-breaker-is-random>

    Parameters
    ----------
    y : array
        Time series to be (de-)randomized.
    bound : float
        Lower or upper bound of values in time series.
    threshold : float
        Lower or upper threshold of values in time series.
    inverse : boolean
        If True, values beyond threshold in y are set to bound.
        If False, values beyond threshold in y are randomized.
    power : float
        Numbers for randomizing values are drawn from a uniform distribution
        and then taken to this power.
    lower : boolean
        If True/False, consider bound and threshold to be lower/upper bound and
        lower/upper threshold, respectively.

    """
    if lower: i = y <= threshold
    else: i = y >= threshold
    if inverse:
        y[i] = bound
    else:
        n = np.sum(i)
        if n:
            p = np.power(np.random.uniform(0, 1, n), power)
            v = bound + p * (threshold - bound)
            s = Series(y[i])
            r = s.sample(frac=1).rank(method='first').reindex_like(s)
            y[i] = np.sort(v)[r.values.astype(int) - 1]



def randomize_censored_values(x,
        lower_bound=None, lower_threshold=None,
        upper_bound=None, upper_threshold=None,
        inplace=False, inverse=False,
        seed=None, lower_power=1., upper_power=1.):
    """
    Randomizes values beyond threshold in x or de-randomizes such formerly
    randomized values.

    Parameters
    ----------
    x : array
        Time series to be (de-)randomized.
    lower_bound : float, optional
        Lower bound of values in time series.
    lower_threshold : float, optional
        Lower threshold of values in time series.
    upper_bound : float, optional
        Upper bound of values in time series.
    upper_threshold : float, optional
        Upper threshold of values in time series.
    inplace : boolean, optional
        If True, change x in-place. If False, change a copy of x.
    inverse : boolean, optional
        If True, values beyond thresholds in x are set to the respective bound.
        If False, values beyond thresholds in x are randomized, i.e. values that
        exceed upper_threshold are replaced by random numbers from the
        interval [lower_bound, lower_threshold), and values that fall short
        of lower_threshold are replaced by random numbers from the interval
        (upper_threshold, upper_bound]. The ranks of the censored values are
        preserved using a random tie breaker. 
    seed : int, optional
        Used to seed the random number generator before replacing values beyond
        threshold.
    lower_power : float, optional
        Numbers for randomizing values that fall short of lower_threshold are
        drawn from a uniform distribution and then taken to this power.
    upper_power : float, optional
        Numbers for randomizing values that exceed upper_threshold are drawn
        from a uniform distribution and then taken to this power.

    Returns
    -------
    x : array
        Randomized or de-randomized time series.

    """
    y = x if inplace else x.copy()
    if seed is not None:
        np.random.seed(seed)

    # randomize lower values
    if lower_bound is not None and lower_threshold is not None:
        randomize_censored_values_core(
            y, lower_bound, lower_threshold, inverse, lower_power, True)

    # randomize upper values
    if upper_bound is not None and upper_threshold is not None:
        randomize_censored_values_core(
            y, upper_bound, upper_threshold, inverse, upper_power, False)

    return y



def check_shape_loc_scale(spsdotwhat, shape_loc_scale):
    """
    Analyzes how distribution fitting has worked.

    Parameters
    ----------
    spsdotwhat : sps distribution class
        Known classes are [sps.norm, sps.weibull_min, sps.gamma, sps.rice,
        sps.beta].
    shape_loc_scale : tuple
        Fitted shape, location, and scale parameter values.

    Returns
    -------
    i : int
        0 if everything is fine,
        1 if there are infs or nans in shape_loc_scale,
        2 if at least one value in shape_loc_scale is out of bounds,
        3 if spsdotwhat is unknown.

    """
    if np.any(np.isnan(shape_loc_scale)) or np.any(np.isinf(shape_loc_scale)):
        return 1
    elif spsdotwhat == sps.norm:
        return 2 if shape_loc_scale[1] <= 0 else 0
    elif spsdotwhat in [sps.weibull_min, sps.gamma, sps.rice]:
        return 2 if shape_loc_scale[0] <= 0 or shape_loc_scale[2] <= 0 else 0
    elif spsdotwhat == sps.beta:
        return 2 if shape_loc_scale[0] <= 0 or shape_loc_scale[1] <= 0 \
            or shape_loc_scale[0] > 1e10 or shape_loc_scale[1] > 1e10 else 0
    else:
        return 3



def fit(spsdotwhat, x, fwords):
    """
    Attempts to fit a distribution from the family defined through spsdotwhat
    to the data represented by x, holding parameters fixed according to fwords.

    A maximum likelihood estimation of distribution parameter values is tried
    first. If that fails the method of moments is tried for some distributions.

    Parameters
    ----------
    spsdotwhat : sps distribution class
        Known classes are [sps.norm, sps.weibull_min, sps.gamma, sps.rice,
        sps.beta].
    x : array
        Data to be fitted.
    fwords : dict of str : float
        Keys : 'floc' and (optinally) 'fscale'
        Values : location and (optinally) scale parmeter values that are to be
        held fixed when fitting.

    Returns
    -------
    shape_loc_scale : tuple
        Fitted shape, location, and scale parameter values if fitting worked,
        otherwise None.

    """
    # make sure that there are at least two distinct data points because
    # otherwise it is impossible to fit more than 1 parameter
    if np.unique(x).size < 2:
        msg = 'found fewer then 2 different values in x: returning None'
        warnings.warn(msg)
        return None

    # try maximum likelihood estimation
    try:
        shape_loc_scale = spsdotwhat.fit(x, **fwords)
    except:
        shape_loc_scale = (np.nan,)


    # try method of moment estimation
    if check_shape_loc_scale(spsdotwhat, shape_loc_scale):
        msg = 'maximum likelihood estimation'
        if spsdotwhat == sps.gamma:
            msg += ' failed: method of moments'
            x_mean = np.mean(x) - fwords['floc']
            x_var = np.var(x)
            scale = x_var / x_mean
            shape = x_mean / scale
            shape_loc_scale = (shape, fwords['floc'], scale)
        elif spsdotwhat == sps.beta:
            msg += ' failed: method of moments'
            y = (x - fwords['floc']) / fwords['fscale']
            y_mean = np.mean(y)
            y_var = np.var(y)
            p = np.square(y_mean) * (1. - y_mean) / y_var - y_mean
            q = p * (1. - y_mean) / y_mean
            shape_loc_scale = (p, q, fwords['floc'], fwords['fscale'])
    else:
        msg = ''

    # return result and utter warning if necessary
    if check_shape_loc_scale(spsdotwhat, shape_loc_scale):
        msg += ' failed: returning None'
        warnings.warn(msg)
        return None
    elif msg != '':
        msg += ' succeeded'

    # do rough goodness of fit test to filter out worst fits using KS test
    ks_stat = sps.kstest(x, spsdotwhat.name, args=shape_loc_scale)[0]
    if ks_stat > .5:
        if msg == '': msg = 'maximum likelihood estimation succeeded'
        msg += ' but fit is not good: returning None'
        warnings.warn(msg)
        return None
    else:
        if msg != '':
            warnings.warn(msg)
        return shape_loc_scale




def only_missing_values_in_at_least_one_dataset(data):
    """
    Tests whether there are only missing values in at least one of the datasets
    included in data.

    Parameters
    ----------
    data : dict of str : list of arrays
        Keys : 'obs_hist', 'sim_hist', 'sim_fut'.
        Values : every array represents one climate variable.

    Returns
    -------
    result : bool
        Test result.

    """
    for key, array_list in data.items():
        only_missing_values = True
        for a in array_list:
            if not isinstance(a, np.ma.MaskedArray):
                # a is not masked
                only_missing_values = False
                break
            m = a.mask
            if not isinstance(m, np.ndarray):
                # m is a scalar
                if m:
                    # all values in a are masked
                    continue
                else:
                    # no value in a is masked
                    only_missing_values = False
                    break
            if not np.all(m):
                # at least one value in a is not masked
                only_missing_values = False
                break
        if only_missing_values:
            return True
    return False



def only_missing_values_in_at_least_one_time_series(data):
    """
    Tests whether there are only missing values in at least one time series
    included in data.

    Parameters
    ----------
    data : dict of str : array or ndarray
        Keys : 'obs_fine', 'sim_coarse', 'sim_coarse_remapbil'.
        Values : array (for key 'sim_coarse') or ndarray representing climate
        data per coarse grid cell. The first axis is considered the time axis.

    Returns
    -------
    result : bool
        Test result.

    """
    for key, a in data.items():
        assert a.ndim in [1, 2], f'{key} array has {a.ndim} dimensions'
        if isinstance(a, np.ma.MaskedArray):
            m = a.mask
            if isinstance(m, np.ndarray):
                if a.ndim == 1:
                    if np.all(m): return True
                else:
                    if np.any(np.all(m, axis=0)): return True
            else:
                if m: return True
    return False



def average_respecting_bounds(x,
        lower_bound=None, lower_threshold=None,
        upper_bound=None, upper_threshold=None):
    """
    Average values in x after values <= lower_threshold have been set to
    lower_bound and values >= upper_threshold have been set to upper_bound.

    Parameters
    ----------
    x : array
        Time series to be (de-)randomized.
    lower_bound : float, optional
        Lower bound of values in time series.
    lower_threshold : float, optional
        Lower threshold of values in time series.
    upper_bound : float, optional
        Upper bound of values in time series.
    upper_threshold : float, optional
        Upper threshold of values in time series.

    Returns
    -------
    a : float
        Average.

    """
    y = x.copy()
    if lower_bound is not None and lower_threshold is not None:
        y[y <= lower_threshold] = lower_bound
    if upper_bound is not None and upper_threshold is not None:
        y[y >= upper_threshold] = upper_bound
    return np.mean(y)



def average_valid_values(a, if_all_invalid_use=np.nan,
        lower_bound=None, lower_threshold=None,
        upper_bound=None, upper_threshold=None):
    """
    Returns the average over all valid values in a, where missing/inf/nan values
    are considered invalid, unless there are only invalid values in a, in which
    case if_all_invalid_use is returned. Prior to averaging, values beyond
    threshold are set to the respective bound.

    Parameters
    ----------
    a : array or masked array
        If this is an array then infs and nans in a are replaced.
        If this is a masked array then infs, nans, and missing values in a.data
        are replaced using a.mask to indicate missing values.
    if_all_invalid_use : float, optional
        Used as replacement of invalid values if no valid values can be found.
    lower_bound : float, optional
        Lower bound of values in time series.
    lower_threshold : float, optional
        Lower threshold of values in time series.
    upper_bound : float, optional
        Upper bound of values in time series.
    upper_threshold : float, optional
        Upper threshold of values in time series.

    Returns
    -------
    average : float or array of floats
        Result of averaging. The result is scalar if a is one-dimensional.
        Otherwise the result is an array containing averages for every location.

    """
    # look for missing values, infs and nans
    b = np.ma.masked_invalid(a, copy=False)
    d = b.data
    l_invalid = b.mask

    # compute mean value of all valid values per location
    average1d = lambda x,l : \
        if_all_invalid_use if np.all(l) else average_respecting_bounds(
        x[np.logical_not(l)], lower_bound, lower_threshold,
        upper_bound, upper_threshold)
    space_shape = a.shape[1:]
    if len(space_shape):
        average = np.empty(space_shape, dtype=np.float32)
        for i in np.ndindex(space_shape): 
            j = (slice(None, None),) + i
            average[i] = average1d(d[j], l_invalid[j])
    else:
        average = average1d(d, l_invalid)

    return average



def sample_invalid_values(a, seed=None, if_all_invalid_use=np.nan, warn=False):
    """
    Replaces missing/inf/nan values in a by if_all_invalid_use or by sampling
    from all other values from the same location.

    Parameters
    ----------
    a : array or masked array
        If this is an array then infs and nans in a are replaced.
        If this is a masked array then infs, nans, and missing values in a.data
        are replaced using a.mask to indicate missing values.
    seed : int, optional
        Used to seed the random number generator before replacing invalid
        values.
    if_all_invalid_use : float or array of floats, optional
        Used as replacement of invalid values if no valid values can be found.
    warn : boolean, optional
        Warn user about replacements being made.

    Returns
    -------
    d_replaced : array
        Result of invalid data replacement.
    l_invalid : array
        Boolean array indicating indices of replacement.

    """
    # make sure types and shapes of a and if_all_invalid_use fit
    space_shape = a.shape[1:]
    if len(space_shape):
        msg = 'expected if_all_invalid_use to be an array'
        assert isinstance(if_all_invalid_use, np.ndarray), msg
        msg = 'shapes of a and if_all_invalid_use do not fit'
        assert if_all_invalid_use.shape == space_shape, msg
    else:
        msg = 'expected if_all_invalid_use to be scalar'
        assert np.isscalar(if_all_invalid_use), msg

    # assert that a is a masked array
    if isinstance(a, np.ma.MaskedArray):
        d = a.data
        m = a.mask
        if not isinstance(m, np.ndarray):
            m = np.empty(a.shape, dtype=bool)
            m[:] = a.mask
    else:
        d = a
        m = np.zeros(a.shape, dtype=bool)
    
    # look for missing values
    l_invalid = m
    n_missing = np.sum(l_invalid)
    if n_missing:
        msg = 'found %i missing value(s)'%n_missing
        if warn: warnings.warn(msg)
    
    # look for infs
    l_inf = np.isinf(d)
    n_inf = np.sum(l_inf)
    if n_inf:
        msg = 'found %i inf(s)'%n_inf
        if warn: warnings.warn(msg)
        l_invalid = np.logical_or(l_inf, l_invalid)
    
    # look for nans
    l_nan = np.isnan(d)
    n_nan = np.sum(l_nan)
    if n_nan:
        msg = 'found %i nan(s)'%n_nan
        if warn: warnings.warn(msg)
        l_invalid = np.logical_or(l_nan, l_invalid)
    
    # return d if all values are valid
    n_invalid = np.sum(l_invalid)
    if not n_invalid:
        return d, None
    
    # otherwise replace invalid values location by location
    if len(space_shape):
        d_replaced = np.empty_like(d)
        for i in np.ndindex(space_shape): 
            j = (slice(None, None),) + i
            d_replaced[j] = sample_invalid_values_core(
                d[j], seed, if_all_invalid_use[i], warn, l_invalid[j])
    else:
        d_replaced = sample_invalid_values_core(
            d, seed, if_all_invalid_use, warn, l_invalid)

    return d_replaced, l_invalid



def sample_invalid_values_core(d, seed, if_all_invalid_use, warn, l_invalid):
    """
    Replaces missing/inf/nan values in d by if_all_invalid_use or by sampling
    from all other values.

    Parameters
    ----------
    d : array
        Containing values to be replaced.
    seed : int
        Used to seed the random number generator before sampling.
    if_all_invalid_use : float
        Used as replacement of invalid values if no valid values can be found.
    warn : boolean
        Warn user about replacements being made.
    l_invalid : array
        Indicating which values in a are invalid and hence to be replaced.

    Returns
    -------
    d_replaced : array
        Result of invalid data replacement.

    """
    # return d if all values in d are valid
    n_invalid = np.sum(l_invalid)
    if not n_invalid:
        return d

    # no sampling possible if there are no valid values in d
    n_valid = d.size - n_invalid
    if not n_valid:
        msg = 'found no valid value(s)'
        if np.isnan(if_all_invalid_use):
            raise ValueError(msg)
        else:
            msg += ': setting them all to %f'%if_all_invalid_use
            if warn: warnings.warn(msg)
            d_replaced = np.empty_like(d)
            d_replaced[:] = if_all_invalid_use
            return d_replaced

    # replace invalid values by sampling from valid values
    # shuffle sampled values to mimic trend in valid values
    msg = 'replacing %i invalid value(s)'%n_invalid + \
    ' by sampling from %i valid value(s)'%n_valid
    if warn: warnings.warn(msg)
    l_valid = np.logical_not(l_invalid)
    d_valid = d[l_valid]
    if seed is not None: np.random.seed(seed)
    p_sampled = np.random.random_sample(n_invalid)
    d_sampled = percentile1d(d_valid, p_sampled)
    d_replaced = d.copy()
    if n_valid == 1:
        d_replaced[l_invalid] = d_sampled
    else:
        i_valid = np.where(l_valid)[0]
        r_valid = np.argsort(np.argsort(d_valid))
        r_valid_interp1d = spi.interp1d(i_valid, r_valid, fill_value='extrapolate')
        i_sampled = np.where(l_invalid)[0]
        r_sampled = np.argsort(np.argsort(r_valid_interp1d(i_sampled)))
        d_replaced[l_invalid] = np.sort(d_sampled)[r_sampled]
    return d_replaced



def convert_datetimes(datetimes, to):
    """
    Converts a sequence of datetime objects.

    Parameters
    ----------
    datetimes : sequence of datetime objects
        Conversion source.
    to : str
        Conversion target.

    Returns
    -------
    converted_datetimes : array of ints
        Conversion result.

    """
    if to == 'month_number':
        return np.array([d.month for d in datetimes]).astype(np.uint8)
    elif to == 'year':
        return np.array([d.year for d in datetimes]).astype(np.int16)
    elif to == 'day_of_year':
        return np.array([d.timetuple()[7] for d in datetimes]).astype(np.uint16)
    else:
        raise ValueError(f'cannot convert to {to}')



def adjust_copula_mbcn(x, rotation_matrices=[], n_quantiles=50):
    """
    Applies the MBCn algorithm for an adjustment of the multivariate rank
    distribution of x['sim_fut'].

    Parameters
    ----------
    x : dict of str : list of n arrays
        Keys : 'obs_hist', 'sim_hist', 'sim_fut'.
        Values : every array represents one climate variable.
    rotation_matrices : list of (n,n) ndarrays, optional
        List of orthogonal matrices defining a sequence of rotations in variable
        space.
    n_quantiles : int, optional
        Number of quantile-quantile pairs used for non-parametric quantile
        mapping.

    Returns
    -------
    x_sim_fut_ba : list of arrays
        Result of copula adjustment.

    """
    # transform values to standard normal distributions per variable
    # stack resulting arrays row wise
    y = {}
    for key in x:
        y[key] = np.stack([sps.norm.ppf((np.argsort(np.argsort(xi))+.5)/xi.size)
                           for xi in x[key]])

    # initialize total rotation matrix
    n_variables = len(x['sim_fut'])
    o_total = np.diag(np.ones(n_variables))

    # iterate
    for o in rotation_matrices:
        o_total = np.dot(o, o_total)

        # rotate data
        for key in y:
            y[key] = np.dot(o, y[key])

        # do univariate non-parametric quantile delta mapping for every variable
        for i in range(n_variables):
            y_sim_hist_old = y['sim_hist'][i].copy()
            y['sim_hist'][i] = map_quantiles_non_parametric_trend_preserving(
                y['obs_hist'][i], y_sim_hist_old, y_sim_hist_old,
                'additive', n_quantiles)
            y['sim_fut'][i] = map_quantiles_non_parametric_trend_preserving(
                y['obs_hist'][i], y_sim_hist_old, y['sim_fut'][i],
                'additive', n_quantiles)

    # rotate back to original axes
    y['sim_fut'] = np.dot(o_total.T, y['sim_fut'])

    # shuffle x_sim_fut according to the result of the copula adjustment
    x_sim_fut_ba = []
    for i in range(n_variables):
        r_sim_fut_ba = np.argsort(np.argsort(y['sim_fut'][i]))
        x_sim_fut_ba.append(np.sort(x['sim_fut'][i])[r_sim_fut_ba])

    return x_sim_fut_ba



def generateCREmatrix(n):
    """
    Returns a random orthogonal n x n matrix from the circular real ensemble
    (CRE), see Mezzadri (2007) <http://arxiv.org/abs/math-ph/0609050v2>

    Parameters
    ----------
    n : int
        Number of rows and columns of the CRE matrix.

    Returns
    -------
    m : (n,n) ndarray
        CRE matrix.

    """
    z = np.random.randn(n, n)
    q, r = spl.qr(z)  # QR decomposition
    d = np.diagonal(r)
    return q * (d / np.abs(d))



def generate_rotation_matrix_fixed_first_axis(v, transpose=False):
    """
    Generates an n x n orthogonal matrix whose first row or column is equal to
     v/|v|, and whose other rows or columns are found by Gram-Schmidt
    orthogonalisation of v and the standard unit vectors except the first.

    Parameters
    ----------
    v : (n,) array
        Array of n non-zero numbers.
    transpose : boolean, optional
        If True/False generate an n x n orthogonal matrix whose first row/column
        is equal to v/|v|.

    Returns
    -------
    m : (n,n) ndarray
        Rotation matrix.

    """
    assert np.all(v > 0), 'all elements of v have to be positive'

    # generate matrix of vectors that span the R^n with v being the first vector
    a = np.diag(np.ones_like(v))
    a[:,0] = v

    # use QR decomposition for Gram-Schmidt orthogonalisation of these vectors
    q, r = spl.qr(a)

    return -q.T if transpose else -q
