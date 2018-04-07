# FROM       ubuntu:16.04
FROM nvidia/cuda:9.1-cudnn7-devel-ubuntu16.04
MAINTAINER Je-Hoon Song "song.jehoon@gmail.com"

RUN apt-get update && apt-get install -y sudo git python3-pip python3-dev && cd /usr/local/bin && ln -s /usr/bin/python3 python && pip3 install --upgrade pip

# deps for openbabel 
RUN apt-get -y install cmake libcairo2-dev zlib1g-dev libxml2-dev python-dev gcc make g++

# deps for rdkit
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && apt-get update && apt-get -y upgrade && apt-get install -y build-essential software-properties-common && apt-get install -y byobu curl git htop man unzip wget && apt-get install -y cmake flex bison python-numpy python-dev sqlite3 libsqlite3-dev libboost-dev libboost-system-dev libboost-thread-dev libboost-serialization-dev libboost-python-dev libboost-regex-dev && apt-get clean && rm -rf /var/lib/apt/lists/* 

#   Add user  
RUN echo "root:docker" | chpasswd

#   Directory setting 
ENV EMR_HOME /root
ENV SCRATCH_DIR ${EMR_HOME}/scratch
ENV EMR_PACKAGE_DIR /usr/local/emr
ENV OB_BUILD ${SCRATCH_DIR}/openbabel_build
ENV OB_INSTALL ${EMR_PACKAGE_DIR}/openbabel
WORKDIR ${EMR_HOME}/scratch 

#   OpenBabel 
RUN mkdir -p ${OB_BUILD} && mkdir -p ${OB_INSTALL} && mkdir -p ${EMR_PACKAGE_DIR}

# COPY packages/openbabel-2.4.1.tar.gz ${SCRATCH_DIR}
RUN wget https://ndownloader.figshare.com/files/10939556 -O ${SCRATCH_DIR}/openbabel-2.4.1.tar.gz 

# Copy Eigen3 
# COPY packages/3.3.3.tar.gz ${SCRATCH_DIR}
RUN wget https://ndownloader.figshare.com/files/10939547 -O ${SCRATCH_DIR}/3.3.3.tar.gz

RUN tar xvfz openbabel-2.4.1.tar.gz 
RUN tar xvfz 3.3.3.tar.gz

# openbabel configuration for compile 
RUN cd ${OB_BUILD} && cmake ${SCRATCH_DIR}/openbabel-2.4.1 -DCMAKE_INSTALL_PREFIX=${OB_INSTALL} -DEIGEN3_INCLUDE_DIR=${SCRATCH_DIR}/eigen-eigen-67e894c6cd8f -DPYTHON_BINDINGS=ON -DBUILD_GUI=OFF
RUN cd ${OB_BUILD} && make -j4 && make install

# RDKIT
# Set RDKit version
ENV RDKIT_VERSION Release_2016_03_3
# # Set environmental variables
ENV RDBASE ${EMR_PACKAGE_DIR}/rdkit-$RDKIT_VERSION
WORKDIR ${EMR_PACKAGE_DIR}

# Compile rdkit
# COPY packages/$RDKIT_VERSION.tar.gz ${EMR_PACKAGE_DIR}
RUN wget https://ndownloader.figshare.com/files/10939562 -O ${EMR_PACKAGE_DIR}/$RDKIT_VERSION.tar.gz 
RUN tar xzvf $RDKIT_VERSION.tar.gz && rm -f $RDKIT_VERSION.tar.gz
RUN cd ${RDBASE}/External/INCHI-API && ./download-inchi.sh
RUN mkdir -p ${RDBASE}/build
RUN cd ${RDBASE}/build && cmake -DRDK_BUILD_INCHI_SUPPORT=ON .. && make -j4 && make install

RUN pip install virtualenv ipython pytest pandas numpy scipy ipdb pympler tqdm xmljson py2neo psycopg2 goatools cmapPy
RUN apt-get update && apt-get install python-mysql.connector && pip install mysql-connector==2.1.4

ENV PATH /opt/bin:${PATH}

RUN wget https://ndownloader.figshare.com/files/10939553 -O goatools-downloaded-201712.tar.gz
RUN pip install scipy
RUN gzip -d goatools-downloaded-201712.tar.gz && tar xvf goatools-downloaded-201712.tar
RUN cd goatools && python setup.py install 
RUN cd .. && rm -rf goatools

# Etc
RUN apt-get update && apt-get install -y pbzip2

# finallize ..
RUN chown -R root:root ${EMR_HOME} 
RUN chown -R root:root ${EMR_PACKAGE_DIR} 
RUN rm -rf ${SCRATCH_DIR}

# sshd 
RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# file ownership
RUN chown -R root:root ${EMR_HOME} 
RUN /usr/bin/ssh-keygen -A
RUN chsh -s /bin/bash root

WORKDIR ${EMR_HOME}

# Python Env 
RUN apt-get update && apt-get install -y build-essential git curl wget bash-completion openssh-server gfortran sudo make  cmake libssl-dev libreadline-dev llvm libsqlite3-dev libmysqlclient-dev python-dev python3-dev zlib1g-dev libbz2-dev language-pack-ko

# COPY packages/vim.tar.gz ${EMR_HOME}/
# VIM should be installed twice 
RUN apt-get install -y vim 
RUN wget https://ndownloader.figshare.com/files/10597954 -O ${EMR_HOME}/vim.tar.gz

RUN cd ${EMR_HOME} && tar xvfz vim.tar.gz 

RUN cd ${EMR_HOME}/vim && ./configure --with-features=huge --enable-multibyte --enable-rubyinterp --enable-pythoninterp=dynamic --with-python-config-dir=/usr/lib/python2.7/config-x86_64-linux-gnu --enable-python3interp=dynamic --with-python3-config-dir=/usr/lib/python3.5/config-3.5m-x86_64-linux-gnu --disable-gui --enable-cscope --prefix=/usr
RUN cd ${EMR_HOME}/vim && make VIMRUNTIMEDIR=/usr/share/vim/vim74 && make -j4 install

WORKDIR ${EMR_HOME}
RUN cd ${EMR_HOME} && rm -rf vim

# COPY packages/neobundle.sh ${EMR_HOME}
RUN wget https://ndownloader.figshare.com/files/10939550 -O ${EMR_HOME}/neobundle.sh

RUN cd ${EMR_HOME} && sh ./neobundle.sh && rm -f ./neobundle.sh 

# supertab
WORKDIR ${EMR_HOME}

COPY .vimrc ${EMR_HOME}/.vimrc
COPY .vim ${EMR_HOME}/.vim

RUN vim +NeoBundleInstall +qall

# COPY packages/supertab.vmb . 
RUN wget https://ndownloader.figshare.com/files/10939565 -O ${EMR_HOME}/supertab.vmb
RUN vim -c 'so %' -c 'q' ${EMR_HOME}/supertab.vmb && rm -f ${EMR_HOME}/supertab.vmb

# ETC 
USER root 
ENV LC_ALL=C
RUN apt-get install -y net-tools 

# Jupyter Notebook 
RUN pip install pytest-xdist jupyter jupyterlab matplotlib-venn sympy sklearn ipywidgets
RUN mkdir -p -m 700 ${EMR_HOME}/.jupyter/ 
COPY jupyter_notebook_config.py ${EMR_HOME}/.jupyter/
RUN jupyter serverextension enable --py jupyterlab --sys-prefix
RUN curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
RUN apt-get update && apt-get install -y nodejs
RUN jupyter nbextension enable --py widgetsnbextension
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager

RUN apt-get update && apt-get install -y python3-tk

# Copy public keys to connect to the docker without password
RUN ssh-keygen -t rsa -f ${EMR_HOME}/.ssh/id_rsa -q -P ""
COPY public_keys ${EMR_HOME}
RUN cat ${EMR_HOME}/public_keys >> ${EMR_HOME}/.ssh/authorized_keys && chmod 600 ${EMR_HOME}/.ssh/authorized_keys && rm -f ${EMR_HOME}/public_keys

# Copy github config file 
# COPY .gitconfig .

# file ownership
RUN chown -R root:root ${EMR_HOME} 

# Set usr env variables 
ENV LD_LIBRARY_PATH ${RDBASE}/lib:${LD_LIBRARY_PATH}
ENV PYTHONPATH ${OB_INSTALL}/lib:${OB_INSTALL}/lib/python3.5/site-packages:${RDBASE}:${PYTHONPATH}:/usr/local/lib/python3.5/dist-packages
ENV PATH ${OB_INSTALL}/bin:${PATH}
ENV PYTHONIOENCODING utf-8
COPY .bashrc bashrc

ENV PROFILE ${EMR_HOME}/.bashrc

# ENV PROFILE /etc/profile
RUN echo "# extra env setting" >> $PROFILE
RUN echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> $PROFILE
RUN echo "export PYTHONPATH=$PYTHONPATH" >> $PROFILE
RUN echo "export PATH=$PATH" >> $PROFILE
RUN echo "export PYTHONIOENCODING=$PYTHONIOENCODING" >> $PROFILE
RUN echo "export LANG=en_US.UTF-8" >> $PROFILE 
RUN cat bashrc >> $PROFILE
RUN rm -f bashrc
RUN chown -R root:root ${EMR_HOME} 

ENV EMR_SCRATCH_DIR="$EMR_HOME/.scratch"
ENV EMR_DATASETS_BASE="http://192.168.0.89/share/StandigmDB/datasets"

# jupyter widgets ...
RUN pip install ipyleaflet bqplot 
RUN jupyter nbextension enable --py --sys-prefix ipyleaflet
RUN jupyter nbextension enable --py --sys-prefix bqplot

RUN pip install --upgrade --force-reinstall appnope==0.1.0 backports.functools-lru-cache==1.5 bleach==2.1.3 certifi==2018.1.18 cycler==0.10.0 decorator==4.2.1 entrypoints==0.2.3 graphviz==0.8.2 h5py==2.7.1 html5lib==1.0.1 ipykernel==4.8.2 ipython==6.2.1 ipython-genutils==0.2.0 ipywidgets==7.1.2 jedi==0.11.1 Jinja2==2.10 jsonschema==2.6.0 jupyter==1.0.0 jupyter-client==5.2.3 jupyter-console==5.2.0 jupyter-core==4.4.0 Keras==2.0.6 kiwisolver==1.0.1 MarkupSafe==1.0 matplotlib==2.2.2 mistune==0.8.3 mock==2.0.0 nbconvert==5.3.1 nbformat==4.4.0 notebook==5.4.1 numpy==1.14.2 olefile==0.45.1 pandas==0.22.0 pandocfilters==1.4.2 parso==0.1.1 pbr==3.1.1 pexpect==4.4.0 pickleshare==0.7.4 Pillow==5.0.0 prompt-toolkit==1.0.15 protobuf==3.5.2 ptyprocess==0.5.2 pydot==1.2.3 Pygments==2.2.0 pyparsing==2.2.0 python-dateutil==2.7.0 pytz==2018.3 PyYAML==3.12 pyzmq==17.0.0 qtconsole==4.3.1 scikit-learn==0.19.1 scipy==1.0.0 Send2Trash==1.5.0 simplegeneric==0.8.1 six==1.11.0 tensorflow==1.0.0 terminado==0.8.1 testpath==0.3.1 Theano==1.0.1 tornado==5.0.1 traitlets==4.3.2 wcwidth==0.1.7 webencodings==0.5.1 widgetsnbextension==3.1.4 

RUN pip install git+https://github.com/aspuru-guzik-group/chemical_vae.git
RUN apt-get install -y python3-pydot graphviz
RUN pip install pydot_ng

RUN python -c "import openbabel; import pybel; import rdkit"

ENV PYTHONPATH ${PYTHONPATH}:/root/share

EXPOSE 8888 22

VOLUME ${EMR_HOME}

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"] 

CMD ["emr"]


