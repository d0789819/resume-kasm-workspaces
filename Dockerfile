FROM kasmweb/core-cuda-jammy:1.17.0

USER root
ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
WORKDIR $HOME

########## Customize Container Here ##########
# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        apt-transport-https \
        apt-utils \
        build-essential \
        ca-certificates \
        curl \
        dirmngr \
        fonts-liberation \
        gfortran \
        gnupg \
        libasound2 \
        libatk-bridge2.0-0 \
        libatlas-base-dev \
        libbz2-dev \
        libcurl4-openssl-dev \
        libegl1-mesa \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libgtk-3-0 \
        libice6 \
        libicu-dev \
        liblzma-dev \
        libnss3 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libpcre3-dev \
        libpq5 \
        libsm6 \
        libssl-dev \
        libtiff5 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-render-util0 \
        libxcb-xinerama0 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxi6 \
        libxkbcommon-x11-0 \
        libxml2-dev \
        libxrandr2 \
        libxrender1 \
        libxss1 \
        libxt6 \
        libxtst6 \
        lsb-release \
        make \
        pandoc \
        r-base \
        software-properties-common \
        sudo \
        wget \
        zlib1g-dev \
    && apt-get -f install -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome
COPY resources/web_browser/google_chrome.sh /tmp
RUN bash /tmp/google_chrome.sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# Install Microsoft Edge
COPY resources/web_browser/microsoft_edge.sh /tmp
RUN bash /tmp/microsoft_edge.sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# Install Anaconda
RUN wget -P /tmp https://repo.anaconda.com/archive/Anaconda3-2023.03-1-Linux-x86_64.sh \
    && bash /tmp/Anaconda3-2023.03-1-Linux-x86_64.sh -b -p /opt/anaconda3 \
    && echo "source /opt/anaconda3/bin/activate" >> /etc/bash.bashrc \
    && /opt/anaconda3/bin/conda update -n root conda -y \
    && /opt/anaconda3/bin/conda update --all -y \
    && /opt/anaconda3/bin/conda config --set ssl_verify /etc/ssl/certs/ca-certificates.crt \
    && /opt/anaconda3/bin/conda install pip -y \
    && /opt/anaconda3/bin/conda clean --all -y \
    && mkdir -p $HOME/.conda $HOME/.pip $HOME/.cache \
    && chown -R 1000:1000 /opt/anaconda3 $HOME/.conda $HOME/.pip $HOME/.cache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# Install Visual Studio Code
RUN wget -O /tmp/code_amd64.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" \
    && apt-get update \
    && apt-get install -y /tmp/code_amd64.deb \
    && apt-get -f install -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# Install Visual Studio Code extensions
COPY resources/visual_studio_code_extension/*.vsix /tmp
RUN for vsix in /tmp/*.vsix; do \
        /usr/share/code/bin/code --install-extension "$vsix" --no-sandbox --user-data-dir=/tmp; \
    done \
    && rm -rf /tmp/*

# Install RStudio Desktop
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc \
    && add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" \
    && wget -P /tmp https://download1.rstudio.org/electron/jammy/amd64/rstudio-2025.05.1-513-amd64.deb \
    && apt-get update \
    && apt-get install -y /tmp/rstudio-2025.05.1-513-amd64.deb \
    && apt-get -f install -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc

# Copy desktop files and icons
COPY resources/desktop_shortcut/labelme.desktop $HOME/Desktop/
COPY resources/desktop_shortcut/labelme_icon.png /opt/anaconda3/icon/labelme.png
COPY resources/desktop_shortcut/jupyterlab.desktop $HOME/Desktop/
COPY resources/desktop_shortcut/jupyter_notebook.desktop $HOME/Desktop/
COPY resources/desktop_shortcut/spyder.desktop $HOME/Desktop/
COPY resources/desktop_shortcut/visual_studio_code.desktop $HOME/Desktop/
COPY resources/desktop_shortcut/rstudio_desktop.desktop $HOME/Desktop/

# Add environment variables before user switch
ENV QT_QPA_PLATFORM_PLUGIN_PATH=/opt/anaconda3/plugins/platforms
ENV XDG_RUNTIME_DIR=/tmp/runtime-default

# Install Python packages in the conda environment
RUN /opt/anaconda3/bin/conda install -y -c conda-forge \
        jupyterlab \
        labelme \
        spyder \
    && /opt/anaconda3/bin/pip install --no-cache-dir \
        notebook \
    && /opt/anaconda3/bin/conda clean --all -y
########## End Customizations ##########

RUN chown -R 1000:0 $HOME
ENV HOME=/home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME

USER 1000
CMD ["--tail-log"]
