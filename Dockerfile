# Start with 0.5.0 which is also latest at the moment
FROM julia:1.3.0

# Install stuff needed by the HttpParser package
RUN apt-get update && apt-get install -y \
    zip \
    unzip \
    build-essential \
    make \
    gcc \
    libzmq3-dev

# Make package folder and install everything in require
ENV JULIA_PKGDIR=/opt/julia
RUN julia -e "Pkg.activate()"
COPY Project.toml /opt/julia/v1.3.0/Project.toml
RUN julia -e "Pkg.instantiate()"

# Build all the things
RUN julia -e 'Pkg.build()'

# Build those things which are mysteriously not included in the list of all things, then use all modules to force precompile
RUN julia -e 'Pkg.build("Plots"); Pkg.build("SymEngine"); Pkg.rm("Conda")'

# Clone WebBase
RUN julia -e 'Pkg.add(PackageSpec(url="https://github.com/JuliaDiffEq/DiffEqWebBase.jl", rev="master"));'

# Check out master until patches
RUN julia -e 'Pkg.add(PackageSpec(name="DiffEqBase", rev="master")); Pkg.add(PackageSpec(name="OrdinaryDiffEq", rev="master")); Pkg.add(PackageSpec(name="StochasticDiffEq", rev="master")); Pkg.add(PackageSpec(name="ParameterizedFunctions", rev="master"));'

# Force precompile of all modules -- this should greatly improve startup time
RUN julia -e 'using DiffEqBase, DiffEqWebBase, OrdinaryDiffEq, StochasticDiffEq, ParameterizedFunctions, Plots, Mux, JSON, HttpCommon'

COPY /api /api

# Don't run as root
RUN useradd -ms /bin/bash myuser
RUN chown -R myuser:myuser /opt/julia
USER myuser

CMD julia /api/mux_server.jl $PORT
