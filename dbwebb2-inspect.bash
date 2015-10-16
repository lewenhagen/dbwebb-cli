# --------------- DBWEBB-INSPECT MAIN START HERE ---------------
#
# Settings
#
WRAP_HEADER="\n\n\n-------------------------------------------------------------"
WRAP_FOOTER="\n-------------------------------------------------------------"



#
# Write header for each test
#
headerForTest()
{
    what="$1"
    task="$2"

    pressEnterToContinue
    
    printf "$WRAP_HEADER"
    printf "\n$what"
    if [ ! -z "$task" ]; then
        printf "\n$task"
    fi
    printf "$WRAP_FOOTER"
}


#
# Open files in editor
#
openFilesInEditor()
{
    printf "\nOpen files in an editor:"
    printf "\n$EDITOR \"%s/%s\"" "$THEDIR" "$1"
    printf "\n"
}



#
# Open files in editor
#
viewFileTree()
{
    local dirname="$THEDIR/$1"

    printf "\nView content of directory:\n"
    tree -ph "$dirname"
}



#
# Change to directory
#
changeToDirectory()
{
    local dirname="$THEDIR/$1"
    
    printf "\ncd \"%s/%s\"" "$THEDIR" "$1"
    printf "\n"
}



#
# Print url and check if it exists
#
printUrl()
{
    local what="$1"
    local where="$2"
    
    printf "\nURL: $BASE_URL/$DBW_COURSE/$where/$what"

    if [ -z "$what" ]; then
        assert 0 "test -d \"$THEDIR/$where\"" "The directory '$where' is missing or not readable."
    else
        assert 0 "test -f \"$THEDIR/$where/$what\"" "The file '$what' is missing or not readable."
    fi

    printf "\n"
}



#
# Check if file exists and display it 
#
viewFileContent()
{
    local file="$1"
    local dir="$2"
    local fileAlt="$3"
    
    if [ ! -f "$THEDIR/$dir/$file" ]; then 
        if [ -f "$THEDIR/$dir/$fileAlt" ]; then
            file="$fileAlt"
        fi
    fi
    
    assert 0 "test -f \"$THEDIR/$dir/$file\"" "The file '$file' is missing or not readable."

    if [ $? -eq 0 ]; then
        printf "\nView file '%s' [Yn]? " "$file"

        read answer
        default="y"
        answer=${answer:-$default}

        if [ "$answer" = "y" -o "$answer" = "Y" ]
        then
            echo ">>>"
            less --quit-if-one-screen --no-init "$THEDIR/$dir/$file"
            echo "<<<"
            pressEnterToContinue
        fi
    fi
}



#
# Test check the kmom dir exists
#
checkKmomDir()
{
    local dirname="$THEDIR/$1"
    
    assert 0 "test -r $dirname -a -d $dirname" "Directory $dirname not readable."
}



#
# Test check the file exists and is readable
#
fileIsReadable()
{
    local filename="$THEDIR/$1"
    
    assert 0 "test -r $filename" "The file $filename is not readable."
}



#
# Test general
#
function inspectIntro()
{
    local target="me/$KMOM"

    headerForTest "-- $DBW_COURSE $KMOM" "-- ${DBW_WWW}$DBW_COURSE/$KMOM"
    checkKmomDir "$target"
    publishKmom
    viewFileTree "$target"
    validateKmom "$KMOM"
}



#
# The me-page
#
function inspectMe()
{
    local target="$1"
    local mepage="$2"
    local reportpage="$3"
    local assignment="$4"

    if [ ! -z "$assignment" ]; then
        assignment="\n-- ${DBW_WWW}$assignment"
    fi

    headerForTest "-- me-page" "-- ${DBW_WWW}$DBW_COURSE/$KMOM#resultat_redovisning$assignment" 
    checkKmomDir "$target"
    viewFileTree "$target"
    openFilesInEditor "$target"

    printUrl "$mepage" "$target"  
    printUrl "$reportpage" "$target"  
}



#
# Test a exercise
#
inspectExercise()
{
    local exercise="$1"
    local url="$2"
    local file1="$3"
    local file2="$4"
    local file3="$5"
    local file4="$6"
    local file5="$7"
    local file6="$8"
    local file7="$9"
    local file8="${10}"
    local info="${11}"
    local target="me/$KMOM/$exercise"

    headerForTest "-- $exercise$info" "-- ${DBW_WWW}$url"
    checkKmomDir "$target"
    viewFileTree "$target"
    openFilesInEditor "$target"
    
    # As files
    [ -z "$file1" ] || viewFileContent "$file1" "$target"
    [ -z "$file2" ] || viewFileContent "$file2" "$target"

    # As urls
    [ -z "$file3" ] || printUrl "$file3" "$target"
    [ -z "$file4" ] || printUrl "$file4" "$target"

    # As commands
    [ -z "$file5" -a -z "$file6" ] || inspectCommand "$file5" "$THEDIR/$target" "$file6"
    [ -z "$file7" -a -z "$file8" ] || inspectCommand "$file7" "$THEDIR/$target" "$file8"
}



#
# Check the environment
#
dbwebbInspectTargetNotReadable()
{
    local thedir="$( readlink -f "$REPO" )"
    
    if [ ! -d "$thedir" ]; then 
        
        printf "\n$MSG_FAILED Directory '$REPO' not readable.\n"

        local dirname=$( dirname "$REPO" )
        if [ ! -r "$dirname" ]; then 
            printf "\n$MSG_FAILED Directory '$dirname' not readable.\n"
        else
            printf "\nDirectory '$dirname' exists, doing an ls.\n"
            ls "$dirname"
        fi
        
        printf "\n$MSG_FAILED Perhaps login to the studserver and execute the command:\n"
        echo "sudo setpre-dbwebb-kurser.bash $THEUSER"
        echo  
    fi 
}



#
# Check the environment
#
dbwebbInspectCheckEnvironment()
{
    headerForTest "-- dbwebb inspect"
    printUrl "" "me"
    openFilesInEditor "me"
    changeToDirectory "me"
}



#
# Make own copy
#
publishKmom()
{
    [[ $COPY_DIR ]] || return
    
    rm -rf "$COPY_DIR"
    mkdir "$COPY_DIR"
    
    printf "\nPublishing a copy of %s to '%s'" "$KMOM" "$COPY_DIR"
    rsync -a --exclude 'kmom*' "$THEDIR/me/" "$COPY_DIR/"
    rsync -a "$THEDIR/me/$KMOM/" "${COPY_DIR}${KMOM}/"
    
    publishChmod "$COPY_DIR"

    printf "\nURL: %s" "$COPY_URL"
    printf "\n"

    printf "\nOpen files in an editor:"
    printf "\n$EDITOR \"%s\"" "$COPY_DIR"
    printf "\n"

    printf "\nChange to directory:"
    printf "\ncd \"%s\"" "$COPY_DIR"
    printf "\n"
}



#
# Test validate a kmom
#
validateKmom()
{
    local kmom=${1-$KMOM}
    
    printf "\nValidate %s [Yn]? " "$kmom"

    read answer
    default="y"
    answer=${answer:-$default}

    if [ "$answer" = "y" -o "$answer" = "Y" ]
    then
        dbwebb-validate --course-repo "$DBW_COURSE_DIR" "$kmom"
    fi
}



#
# Execute a command, maybe as another user
# TODO remove support for $4 $opts, its not really used, but check in python & js1 before doing it.
#
inspectCommand()
{
    local what="$1"
    local move="$2"
    local cmd="$3"
    local opts="$4"

    filename="$move/$what"

    if [ ! -z "$what" ]; then
        assert 0 "test -f \"$filename\" -o -r \"$filename\"" "The file '$what' is missing or not readable."
    fi
    
    if [ $? == 0 ]; then
        printf "\nExecute '%s' [Yn]? " "$cmd"
        read answer
        default="y"
        answer=${answer:-$default}

        if [ "$answer" = "y" -o "$answer" = "Y" ]; then

            pushd "$move" > /dev/null
            echo ">>>"
            $cmd
            status=$?
            echo "<<<"
            popd > /dev/null

            if [ $status -eq 0 ]; then
                assert 1 "test" "Command executed successfully."
                printf "\n$MSG_OK Command executed with a exit status 0  - indicating success."
                printf "\n"
            else
                assert 0 "test" "Command returned non-zero exit status which might indicate failure."
            fi
        fi
    fi
}



#
# Execute a command as a server in the background logging output to a file.
#
runServer()
{
    local what="$1"
    local move="$2"
    local cmd="$3"
    local opts="$4"

    local filename="$move/$what"
    
    local logfile=".serverlog.txt"
    SERVER_LOG="$move/$logfile"

    if [ ! -z "$what" ]; then
        assert 0 "test -f \"$filename\" -o -r \"$filename\"" "The file '$what' is missing or not readable."
    fi
    
    if [ $? == 0 ]; then
        printf "\nExecute '%s' as server and log its output to '$logfile' [Yn]? " "$cmd"
        read answer
        default="y"
        answer=${answer:-$default}

        if [ "$answer" = "y" -o "$answer" = "Y" ]; then

            pushd "$move" > /dev/null
            echo ">>>"
            $cmd > "$SERVER_LOG" &
            status=$?
            SERVER_PID=$!
            echo "$cmd started with pid $SERVER_PID."
            echo -n "Will kill server automatically within 60 seconds."
            sleep 60 && kill $SERVER_PID &
            echo "Sleeping 3 before continuing."
            sleep 3
            echo "<<<"
            popd > /dev/null

            if [ $status -eq 0 ]; then
                assert 1 "test" "Command executed successfully."
                printf "\n$MSG_OK Command executed with a exit status 0  - indicating success."
                printf "\n"
            else
                assert 0 "test" "Command returned non-zero exit status which might indicate failure."
            fi
        fi
    fi
}



#
# Kill the server started with startServer and output its logfile.
#
killServer()
{
    echo "Killing server."
    echo ">>>"
    kill $SERVER_PID
    echo "Sent kill signal to server."
    echo "Sleeping 3 before continuing."
    sleep 3
    echo "Printing logfile from server:"
    cat "$SERVER_LOG"
    echo "<<<"
}



#
# Process options
#
while (( $# ))
do
    case "$1" in
        
        --help | -h)
            usage
            exit 0
        ;;
        
        --version | -v)
            version
            exit 0
        ;;
                
        --selfupdate)
            selfupdate dbwebb-inspect
            exit 0
        ;;
        
        --archive)
            if [ ! -d "$2" ]; then
                badUsage "Path to --archive '$2' is not a directory."
                exit 2                
            fi
            ARCHIVE="$2"
            shift
            shift
        ;;
        
        --config)
            if [ ! -f "$2" ]; then
                badUsage "Path to --config '$2' is not a file."
                exit 2                
            fi
            DBW_INSPECT_CONFIGFILE="$2"
            shift
            shift
        ;;
        
        --publish-to)
            if [ ! -d "$2" ]; then
                badUsage "Path to --publish-to '$2' is not a directory."
                exit 2                
            fi
            COPY_DIR="$2/inspect/"
            shift
            shift
        ;;
        
        --publish-url)
            COPY_URL="$2/inspect/"
            shift
            shift
        ;;

        --base-url)
            BASE_URL="$2"
            shift
            shift
        ;;

        *) 
            break
        ;;
        
    esac
done



#
# Get path to dir to check
#
REPO="$1"
KMOM="$2"



#
# Check incoming arguments
#
if [ -z "$REPO" ]; then
    badUsage "Missing course repo."
    exit 2
elif [ -z "$KMOM" ]; then
    badUsage "Missing kmom."
    exit 2    
fi

THEDIR=$( readlink -f "$REPO" )
if [ ! -d "$THEDIR" ]; then
    dbwebbInspectTargetNotReadable
    #badUsage "The path '$REPO' is not a valid directory."
    exit 2
fi

DBW_COURSE_DIR="$THEDIR"
sourceCourseRepoFile



#
# Source validate config file
#
[[ $DBW_INSPECT_CONFIGFILE ]] && . "$DBW_INSPECT_CONFIGFILE"



#
# Guess the user as owner of the repo
#
THEUSER=$( ls -ld "$REPO" | awk '{print $3}' )



#
# Guess BASE_URL if not available
#
DBW_WWW_HOST=${DBW_WWW_HOST:=http://www.student.bth.se/}
DBW_REMOTE_BASEDIR=${DBW_REMOTE_BASEDIR:=dbwebb-kurser}
if [[ ! $BASE_URL ]]; then
    BASE_URL="$DBW_WWW_HOST~$THEUSER/$DBW_REMOTE_BASEDIR"    
fi

# Guess COPY_URL if not available
if [[ ! $COPY_URL ]]; then
    COPY_URL="$DBW_WWW_HOST~$USER/$DBW_REMOTE_BASEDIR/inspect/"    
fi

# Check if ARCHIVE should be used
if [[ $ARCHIVE ]]; then
    echo -n "Archiving, please wait..."
    
    if [ ! -d "$ARCHIVE/$THEUSER/$DBW_COURSE" ]; then
        echo -n "creating '$ARCHIVE/$THEUSER/$DBW_COURSE'..."
        install --mode=770 --directory "$ARCHIVE/$THEUSER/$DBW_COURSE"
    fi
    
    rsync -a --no-perms --delete "$THEDIR/me/" "$ARCHIVE/$THEUSER/$DBW_COURSE/"
    find "$ARCHIVE/$THEUSER/$DBW_COURSE/" -user $USER -exec chmod g+w {} \;   
    echo "done."
fi



#
# Decide on target dir for execution
#
if [[ $COPY_DIR ]]; then
    EXEC_DIR="$COPY_DIR"
else
    EXEC_DIR="$THEDIR/me/"
fi


#
# Do inspect
#
echo "#"
echo "# $( date )"
echo "# $( dbwebb-inspect --version )"
echo "#"
echo "# Repo:     $DBW_COURSE_DIR"
echo "# Course:   $DBW_COURSE"
echo "# Kmom:     $KMOM"
echo "# Student:  $THEUSER"
echo "# By:       $USER"
echo "# Archived: $( [[ $ARCHIVE ]] && echo "yes" || echo "no" )"
echo "#"
dbwebbInspectCheckEnvironment



#
# Execute command
#
case "$KMOM" in
    kmom01)     ${DBW_COURSE}; "${DBW_COURSE}${KMOM}" ;;
    kmom02)     ${DBW_COURSE}; "${DBW_COURSE}${KMOM}" ;;
    kmom03)     ${DBW_COURSE}; "${DBW_COURSE}${KMOM}" ;;
    kmom04)     ${DBW_COURSE}; "${DBW_COURSE}${KMOM}" ;;
    kmom05)     ${DBW_COURSE}; "${DBW_COURSE}${KMOM}" ;;
    kmom06)     ${DBW_COURSE}; "${DBW_COURSE}${KMOM}" ;;
    kmom10)     ${DBW_COURSE}; "${DBW_COURSE}${KMOM}" ;;
    *)          
        badUsage "\n$MSG_FAILED Invalid combination of course '$DBW_COURSE' and kmom: '$KMOM'"
        exit 1 
        ;;
esac


#
# Clean up and output results
#
headerForTest "-- dbwebb inspect summary"

if [ $FAULTS -gt 0 ]; then
        printf "\n\n$MSG_FAILED"
        STATUS=1
else 
        printf "\n\n$MSG_OK"
        STATUS=0
fi

printf " Asserts: $ASSERTS Faults: $FAULTS\n"
#pressEnterToContinue
#[[ $COPY_DIR ]] && rm -rf "$COPY_DIR"
exit $STATUS
