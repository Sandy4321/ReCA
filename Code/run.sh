#!/bin/bash

# CONFIG
AIROOT="/home/aroyer/Libs/AI-Toolbox"
EIGEN="/usr/local/include/eigen3/"
LPSOLVE="/usr/local/lib/"
GCC="/usr/bin/g++-4.9"
STDLIB="/usr/lib/gcc/x86_64-linux-gnu/4.9.3/"

# DEFAULT ARGUMENTS
AIBUILD="$AIROOT/build"
AIINCLUDE="$AIROOT/include"
MODE="mdp"
DATA="rd"
PLEVEL="10"
HIST="2"
UPROFILE="0"
DISCOUNT="0.95"
STEPS="1000"
EPSILON="0.01"
PRECISION="0"
VERBOSE="0"
BELIEFSIZE="500"
EXPLORATION="10000"
HORIZON="2"
COMPILE=false

# SET  ARGUMENTS FROM CMD LINE
while getopts "m:d:n:k:u:g:s:h:e:x:b:cpv" opt; do
  case $opt in
    m)
      MODE=$OPTARG
      ;;
    d)
      DATA=$OPTARG
      ;;
    n)
      PLEVEL=$OPTARG
      ;;
    k)
      HIST=$OPTARG
      ;;
    u)
      UPROFILE=$OPTARG
      ;;
    g)
      DISCOUNT=$OPTARG
      ;;
    s)
      STEPS=$OPTARG
      ;;
    p)
      PRECISION=1
      ;;
    v)
      VERBOSE=1
      ;;
    h)
      HORIZON=$OPTARG
      ;;
    e)
      EPSILON=$OPTARG
      ;;
    b)
      BELIEFSIZE=$OPTARG
      ;;
    x)
      EXPLORATION=$OPTARG
      ;;
    c)
      COMPILE=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# SET CORRECT DATA PATHS
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ $DATA = "fm" ]; then
    PROFILES=$UPROFILE
    printf -v BASE "$DIR/Models/Foodmart%d%d%d/foodmart_u%d_k%d_pl%d" "$PROFILES" "$HIST" "$PLEVEL" "$PROFILES" "$HIST" "$PLEVEL"
    if [ ! -f "$BASE.items" ]; then
	echo "File $BASE.items not found"
	echo "exit"
	exit 1
    fi
    DATA="reco"
    NITEMS=$(($(wc -l < "$BASE.items") + 1))
elif [ $DATA = "rd" ]; then
    PROFILES=$PLEVEL
    NITEMS=$PLEVEL
    printf -v BASE "$DIR/Models/Synth%d%d%d/synth_u%d_k%d_pl%d" "$PLEVEL" "$HIST" "$PLEVEL" "$PLEVEL" "$HIST" "$PLEVEL"
    DATA="reco"
elif [ $DATA = "mz" ]; then
    NAME=$PLEVEL
    printf -v BASE "$DIR/Models/%s/%s" "$PLEVEL" "$PLEVEL"
    DATA="maze"
else
    echo "Unkown data mode $DATA"
    echo "exit"
    exit 1
fi
# MDP
if [ $MODE = "mdp" ]; then
# COMPILE
    if [ "$COMPILE" = true ]; then
	echo
	echo "Compiling mainMDP"
	$GCC -O3 -Wl,-rpath,$STDLIB -DNITEMSPRM=$NITEMS -DHISTPRM=$HIST -DNPROFILESPRM=$PROFILES -std=c++11 mazemodel.cpp recomodel.cpp utils.cpp main_MDP.cpp -o mainMDP -I $AIINCLUDE -I $EIGEN -L $AIBUILD -l AIToolboxMDP -l AIToolboxPOMDP -l lpsolve55 -lz -lboost_iostreams
	if [ $? -ne 0 ]; then
	    echo "Compilation failed!"
	    echo "exit"
	    exit 1
	fi
    fi

# RUN
    echo
    echo "Running mainMDP on $BASE"
    ./mainMDP $BASE $DATA $DISCOUNT $STEPS $EPSILON $PRECISION $VERBOSE
    echo
# POMDPs
else
# COMPILE
    if [ "$COMPILE" = true ]; then
	echo
	echo "Compiling mainMEMDP"
	$GCC -O3 -Wl,-rpath,$STDLIB -DNITEMSPRM=$NITEMS -DHISTPRM=$HIST -DNPROFILESPRM=$PROFILES -std=c++11 mazemodel.cpp recomodel.cpp utils.cpp main_MEMDP.cpp -o mainMEMDP -I $AIINCLUDE -I $EIGEN -L $LPSOLVE -L $AIBUILD -l AIToolboxMDP -l AIToolboxPOMDP -l lpsolve55 -lz -lboost_iostreams
	if [ $? -ne 0 ]
	then
	    echo "Compilation failed!"
	    echo "exit"
	    exit 1
	fi
    fi

# RUN
    echo
    echo "Running mainMEMDP on $BASE with $MODE solver"
    ./mainMEMDP $BASE $DATA $MODE $DISCOUNT $STEPS $HORIZON $EPSILON $EXPLORATION $BELIEFSIZE $PRECISION $VERBOSE
    echo
fi
