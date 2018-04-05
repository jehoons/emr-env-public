alias t="pytest -qs"
alias l="ls"
alias ll="ls -l"
alias jup="jupyter notebook --port=8888 --no-browser --ip=0.0.0.0 --allow-root"
alias jupl="jupyter lab --port=8888 --no-browser --ip=0.0.0.0 --allow-root"
export PS1="\[\033[1;34m\]\!\[\033[0m\] \[\033[1;35m\]EMR\[\033[0m\]:\[\033[1;35m\]\W\[\033[0m\]$ "
# standb environment 
#export STANDB_ROOT_DIR="$HOME/StanDB"
#export STANDB_SCRATCH_DIR="$HOME/.scratch"
#export STANDB_DATASETS_BASE="http://192.168.0.89/share/StandigmDB/datasets"
export LC_ALL=C

export dockerhost=`netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2}'`
# for git 
#git config --global user.email "song.jehoon@gmail.com"
#git config --global user.name "Je-Hoon Song"
