import pandas as pd
import matplotlib.pyplot as pyplot

def load_and_clean_data(file_path, drop_cols, metadata_file, metadata_cols):
    df = pd.read_csv(file_path, index_col=False, header=2)
    df = df[df.columns[:-5]]
    df = df.drop(drop_cols, axis=1)
    df = df.fillna(0)

    metadata = pd.read_csv(metadata_file, header=0)
    metadata = metadata[metadata_cols].dropna()

    merged_df = df.merge(metadata, on=['Country Code'])
    merged_df = merged_df.set_index(['Country Name'])
    merged_df = merged_df.drop(['Country Code', 'Region', 'IncomeGroup'], axis=1)

    return merged_df

def top10_values(df, year):
    df_actual = df[year]
    df_sorted = df_actual.sort_values(ascending=False)
    df_top = df_sorted.reset_index().head(10)
    df_top.index = df_top.index + 1

    return df_top.round(2)

def pieplot(df, numofyear, title):
    pyplot.figure(figsize=(12, 20))
    total_num_of_years = len(df.columns)

    for i in range(numofyear):
        pyplot.subplot(numofyear, 2, i + 1)
        df_orig = df.iloc[:, total_num_of_years - (i + 1):total_num_of_years - i]
        col = list(df_orig)
        year = ''.join(col)
        df_sorted = df_orig.sort_values(by=year, ascending=False)

        df_sorted = df_sorted.reset_index()
        df_sorted.index = df_sorted.index + 1
        others = df_sorted[10:].sum()[1]
        top10 = df_sorted[:10]
        top10.loc[11] = ['Other Countries', others]

        ax = top10[year].plot.pie(subplots=False, autopct='%0.1f', fontsize=12, legend=False,
                                  labels=top10['Country Name'], shadow=False, explode=(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                  startangle=90)

        ax.set_xlabel(year)
        ax.set_ylabel("")
        pyplot.title(title)

def multilineplot(df, top, Xlabel, Ylabel, title):
    df_top_10 = pd.DataFrame()
    for i in range(len(top)):
        df_temp = df.loc[top.loc[i, 'Country Name']]
        df_plot = pd.DataFrame({'Year': df_temp.index, top.loc[i, 'Country Name']: df_temp.values})
        df_plot['Year'] = df_plot['Year'].astype('int')
        df_top_10 = pd.concat([df_top_10, df_plot], axis=1, join_axes=[df_plot.index])

    df_top_10 = df_top_10.loc[:, ~df_top_10.columns.duplicated()]
    df_top_10_plot = df_top_10.set_index('Year')
    df_top_10_plot.plot()

    pyplot.plot(df_top_10_plot)
    pyplot.legend()
    pyplot.xlabel(Xlabel)
    pyplot.ylabel(Ylabel)
    pyplot.title(title)

def plot_total_emissions(df, ylabel, title):
    total_per_year = df.sum()
    df_total = pd.DataFrame({'Year': total_per_year.index, 'Total': total_per_year.values})
    df_total['Year'] = df_total['Year'].astype('int')
    pyplot.xlabel("Year")
    pyplot.ylabel(ylabel)
    pyplot.plot(df_total['Year'], df_total['Total'])
    pyplot.title(title)
    pyplot.show()

def main():
    # Load CO2 emission data
    co2emision_metadata_merged = load_and_clean_data(
        "/BusinessIntelligence/Datasets/CO2Emissions/co2emissions_data_worldbank.csv",
        ['Indicator Name', 'Indicator Code'],
        "/BusinessIntelligence/Datasets/CO2Emissions/metadata_country_co2emission.csv",
        ['Country Code', 'Region', 'IncomeGroup']
    )
    top10_co2emittors = top10_values(co2emision_metadata_merged, '2014')
    plot_total_emissions(co2emision_metadata_merged, "Total CO2 Emissions (kt)", "Total CO2 Emissions Per Year")
    pieplot(co2emision_metadata_merged, 4, "Pie Chart of CO2 Emissions of top countries")
    multilineplot(co2emision_metadata_merged, top10_co2emittors.reset_index(drop=True), 'Year', 'Total CO2 Emissions',
                  'Comparison Chart of CO2 Emissions of top countries')

    # Load GDP data
    gdp_metadata_merged = load_and_clean_data(
        "/BusinessIntelligence/Datasets/GDP/gdp_data_worldbank.csv",
        ['Indicator Name', 'Indicator Code'],
        "/BusinessIntelligence/Datasets/GDP/metadata_country_gdp.csv",
        ['Country Code', 'Region', 'IncomeGroup']
    )
    top10_gdp = top10_values(gdp_metadata_merged, '2014')
    plot_total_emissions(gdp_metadata_merged, "Total GDP", "Total GDP Per Year")
    pieplot(gdp_metadata_merged, 4, "Pie Chart of GDP of top countries")
    multilineplot(gdp_metadata_merged, top10_gdp.reset_index(drop=True), 'Year', 'Total GDP',
                  'Comparison Chart of GDP of top countries')

    # Load Population data
    population_metadata_merged = load_and_clean_data(
        "/BusinessIntelligence/Datasets/Population/population_data_worldbank.csv",
        ['Indicator Name', 'Indicator Code'],
        "/BusinessIntelligence/Datasets/Population/metadata_country_population.csv",
        ['Country Code', 'Region', 'IncomeGroup']
    )
    top10_populated = top10_values(population_metadata_merged, '2014')
    plot_total_emissions(population_metadata_merged, "Total Population", "Total Population Per Year")
    pieplot(population_metadata_merged, 4, "Pie Chart of population of top countries")
    multilineplot(population_metadata_merged, top10_populated.reset_index(drop=True), 'Year', 'Total Population',
                  'Comparison Chart of Population of top countries')

if __name__ == "__main__":
    main()
