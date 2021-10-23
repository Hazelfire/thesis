#!/usr/bin/env fish
cd src; zip -r all_data.zip itps.csv counterExampleGenerators.csv counterExampleIntegrations.csv libraries.csv library_data/ itp_github_stats.csv; cd ..; mv src/all_data.zip .;
