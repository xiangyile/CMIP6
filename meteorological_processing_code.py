
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import linregress

def load_data(filename):
    """
    Load meteorological data from a TXT file and return it as a pandas DataFrame.

    Parameters:
    ----------
    filename : str
        The path to the TXT file to be loaded.

    Returns:
    ----------
    data: pandas.DataFrame
        A DataFrame containing the meteorological data loaded from the TXT file.
    """
    data = pd.read_csv(filename, delimiter=';', skiprows=16)  # Adjust for TXT format
    return data

def calculate_monthly_statistics(data, year_column, month_column, value_column):
    """
    Calculate monthly statistics for a specific meteorological parameter.

    Parameters:
    ----------
    data : pandas.DataFrame
        A DataFrame containing meteorological data.
    
    year_column : str
        The name of the column containing year information.
    
    month_column : str
        The name of the column containing month information.
    
    value_column : str
        The name of the column containing the parameter values (e.g., temperature).

    Returns:
    ----------
    monthly_stats : pd.DataFrame
        A DataFrame containing mean, max, and min values for each month.
    """
    return data.groupby([year_column, month_column])[value_column].agg(['mean', 'max', 'min']).reset_index()

def calculate_correlation(data, col1, col2):
    """
    Calculate correlation between two meteorological parameters.

    Parameters:
    ----------
    data : pandas.DataFrame
        A DataFrame containing meteorological data.
    
    col1 : str
        The first column to calculate correlation.
    
    col2 : str
        The second column to calculate correlation.

    Returns:
    ----------
    correlation : float
        Correlation coefficient between the two parameters.
    """
    return data[col1].corr(data[col2])

def identify_anomalies(data, column, threshold=3):
    """
    Identify anomalies in a meteorological dataset based on standard deviation.

    Parameters:
    ----------
    data : pandas.DataFrame
        A DataFrame containing meteorological data.
    
    column : str
        The column to identify anomalies.
    
    threshold : int
        The number of standard deviations to use for identifying anomalies.

    Returns:
    ----------
    anomalies : pd.DataFrame
        A DataFrame containing the rows identified as anomalies.
    """
    mean_val = data[column].mean()
    std_val = data[column].std()
    return data[(data[column] > mean_val + threshold * std_val) | (data[column] < mean_val - threshold * std_val)]

def generate_heatmap(data, x_column, y_column, value_column):
    """
    Generate a heatmap for meteorological data.

    Parameters:
    ----------
    data : pandas.DataFrame
        A DataFrame containing meteorological data.
    
    x_column : str
        The column for the x-axis (e.g., months).
    
    y_column : str
        The column for the y-axis (e.g., years).
    
    value_column : str
        The column containing the values for the heatmap.

    Returns:
    ----------
    - Displays a heatmap for the given data.
    """
    pivot_data = data.pivot(index=y_column, columns=x_column, values=value_column)
    plt.figure(figsize=(10, 8))
    plt.imshow(pivot_data, aspect='auto', cmap='coolwarm', origin='lower')
    plt.colorbar(label=value_column)
    plt.xlabel(x_column, fontsize=12)
    plt.ylabel(y_column, fontsize=12)
    plt.title(f"Heatmap of {value_column}", fontsize=14)
    plt.show()

def compute_linear_regression(data, x_column, y_column):
    """
    Perform linear regression on two meteorological parameters.

    Parameters:
    ----------
    data : pandas.DataFrame
        A DataFrame containing meteorological data.
    
    x_column : str
        The column for the independent variable.
    
    y_column : str
        The column for the dependent variable.

    Returns:
    ----------
    slope : float
        The slope of the regression line.
    intercept : float
        The y-intercept of the regression line.
    r_value : float
        The correlation coefficient.
    """
    slope, intercept, r_value, _, _ = linregress(data[x_column], data[y_column])
    return slope, intercept, r_value

def summarize_statistics(data, columns):
    """
    Summarize statistics (mean, median, std) for multiple meteorological parameters.

    Parameters:
    ----------
    data : pandas.DataFrame
        A DataFrame containing meteorological data.
    
    columns : list of str
        List of columns to summarize.

    Returns:
    ----------
    summary : pd.DataFrame
        A DataFrame containing statistics for each column.
    """
    return data[columns].agg(['mean', 'median', 'std']).T

def classify_weather_conditions(data, temperature_column, precipitation_column):
    """
    Classify weather conditions based on temperature and precipitation thresholds.

    Parameters:
    ----------
    data : pandas.DataFrame
        A DataFrame containing meteorological data.
    
    temperature_column : str
        The column containing temperature data.
    
    precipitation_column : str
        The column containing precipitation data.

    Returns:
    ----------
    conditions : pd.Series
        A series containing classified weather conditions.
    """
    conditions = []
    for _, row in data.iterrows():
        if row[temperature_column] > 30 and row[precipitation_column] < 10:
            conditions.append("Hot and Dry")
        elif row[temperature_column] > 30 and row[precipitation_column] >= 10:
            conditions.append("Hot and Wet")
        elif row[temperature_column] <= 30 and row[precipitation_column] >= 10:
            conditions.append("Cool and Wet")
        else:
            conditions.append("Cool and Dry")
    return pd.Series(conditions)

if __name__ == "__main__":
    input_file = "meteorological_data.txt"
    output_file = "summary_output.txt"

    # Load the data
    data = load_data(input_file)

    # Monthly statistics
    monthly_stats = calculate_monthly_statistics(data, 'Year', 'Month', 'Temperature')

    # Correlation between temperature and precipitation
    correlation = calculate_correlation(data, 'Temperature', 'Precipitation')

    # Identify anomalies in temperature data
    anomalies = identify_anomalies(data, 'Temperature')

    # Generate a heatmap of precipitation over months and years
    generate_heatmap(data, 'Month', 'Year', 'Precipitation')

    # Perform linear regression on temperature and precipitation
    slope, intercept, r_value = compute_linear_regression(data, 'Temperature', 'Precipitation')

    # Summarize statistics for key parameters
    summary_stats = summarize_statistics(data, ['Temperature', 'Precipitation'])

    # Classify weather conditions
    weather_conditions = classify_weather_conditions(data, 'Temperature', 'Precipitation')

    # Print out results
    print("Monthly Statistics:", monthly_stats.head())
    print("Correlation:", correlation)
    print("Regression Slope:", slope, "Intercept:", intercept, "R^2:", r_value**2)
    print("Weather Conditions Sample:", weather_conditions.head())
