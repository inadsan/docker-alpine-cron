#!/bin/bash

. /base/functions

file_env "DB_DIR_SOURCE"
file_env "DB_DIR_TARGET" "/backup"

if [ -z "${DB_DIR_SOURCE}" ]; then
  echo "DB_DIR_SOURCE variable is required. Exiting."
  exit 1
fi

TAR=/bin/tar
COMPRESS=gzip
EXTENSION=.gz

DOW=`LC_ALL=C date +%a`                         # Day of the week e.g. Mon
DOM=`LC_ALL=C date +%d`                         # Date of the Month e.g. 27
DM=`LC_ALL=C date +%Y%m%d_%H%M%S`                # Date and Month e.g. 27Sep
MDel=`LC_ALL=C date --date="$(date +%Y-%m-15) -2 month" +"%Y%m"`
MDel1=`LC_ALL=C date --date="$(date +%Y-%m-15) -1 month" +"%Y%m"`

mkdir -p $DB_DIR_TARGET
#DOM="full"

for org in $DB_DIR_SOURCE*; do
  if [ -d "$org" ]; then
    for project in $org/*; do
      if [ -d "$project" ]; then
        orgname=$(basename "${org}")
        projectname=$(basename "${project}")
        projectdir=$(dirname "${project}")
        backupname="${orgname}-${projectname%.*}"
        if [ $DOM = "full" ] || [ ! -f "$DB_DIR_TARGET/$backupname-dia.his" ]; then
          echo "FULL $backupname"
          rm -f "$DB_DIR_TARGET/$backupname-"*
          $TAR -c -P --level=0 --no-check-device --listed-incremental "$DB_DIR_TARGET/$backupname-full.his" "$projectdir/$projectname" | $COMPRESS | split -a 2 -d -b 1000M - "$DB_DIR_TARGET/$backupname-$DM-full.tar${EXTENSION}.part_"
          cp "$DB_DIR_TARGET/$backupname-full.his" "$DB_DIR_TARGET/$backupname-mes.his" 2>/dev/null
          cp "$DB_DIR_TARGET/$backupname-full.his" "$DB_DIR_TARGET/$backupname-semanal.his" 2>/dev/null
          cp "$DB_DIR_TARGET/$backupname-full.his" "$DB_DIR_TARGET/$backupname-dia.his" 2>/dev/null
        else
          if [ $DOM = "01" ]; then
            if [ $(find "$projectdir/$projectname" -newer "$DB_DIR_TARGET/$backupname-full.his" | wc -l) -gt 0 ]; then
              echo "MES $backupname"
              cp "$DB_DIR_TARGET/$backupname-full.his" "$DB_DIR_TARGET/$backupname-mes.his"
              $TAR -c -P --no-check-device --listed-incremental "$DB_DIR_TARGET/$backupname-mes.his" "$projectdir/$projectname" | $COMPRESS > "$DB_DIR_TARGET/$backupname-$DM-mes.tar${EXTENSION}"
              cp "$DB_DIR_TARGET/$backupname-mes.his" "$DB_DIR_TARGET/$backupname-semanal.his"
              cp "$DB_DIR_TARGET/$backupname-mes.his" "$DB_DIR_TARGET/$backupname-dia.his"
            fi
          else
            if [ $DOW = "Sat" ]; then
              if [ $(find "$projectdir/$projectname" -newer "$DB_DIR_TARGET/$backupname-mes.his" | wc -l) -gt 0 ]; then
                echo "SEMANAL $backupname"
                cp "$DB_DIR_TARGET/$backupname-mes.his" "$DB_DIR_TARGET/$backupname-semanal.his"
                $TAR -c -P --no-check-device --listed-incremental "$DB_DIR_TARGET/$backupname-semanal.his" "$projectdir/$projectname" | $COMPRESS > "$DB_DIR_TARGET/$backupname-$DM-semanal.tar${EXTENSION}"
                cp "$DB_DIR_TARGET/$backupname-semanal.his" "$DB_DIR_TARGET/$backupname-dia.his"
              fi
            else
              if [ $(find "$projectdir/$projectname" -newer "$DB_DIR_TARGET/$backupname-semanal.his" | wc -l) -gt 0 ]; then
                echo "DIA $backupname"
                cp "$DB_DIR_TARGET/$backupname-semanal.his" "$DB_DIR_TARGET/$backupname-dia.his"
                $TAR -c -P --no-check-device --listed-incremental "$DB_DIR_TARGET/$backupname-dia.his" "$projectdir/$projectname" | $COMPRESS > "$DB_DIR_TARGET/$backupname-$DM-dia.tar${EXTENSION}"
              fi
            fi
          fi
        fi
      fi
    done
  fi
done
backup_target ${DB_DUMP_TARGET_SYNC}
if [ $? -eq 0 ] ; then
  for org in $DB_DIR_SOURCE*; do
    if [ -d "$org" ]; then
      for project in $org/*; do
        if [ -d "$project" ]; then
          orgname=$(basename "${org}")
          projectname=$(basename "${project}")
          projectdir=$(dirname "${project}")
          backupname="${orgname}-${projectname%.*}"
          if [ $DOM = "01" ]; then
            echo "Clean MES $backupname"
            find ${DB_DIR_TARGET}* -name "*-dia.tar${EXTENSION}" -exec rm {} \;
            find ${DB_DIR_TARGET}* -name "*-semanal.tar${EXTENSION}" -exec rm {} \;
            rm -f $(/bin/ls -t $DB_DIR_TARGET/"$backupname"-*-mes.tar${EXTENSION} 2> /dev/null | awk 'NR>1')
          else
            if [ $DOW = "Sat" ]; then
              echo "Clean SEMANA $backupname"
              find ${DB_DIR_TARGET}* -name "*-dia.tar${EXTENSION}" -exec rm {} \;
              rm -f $(/bin/ls -t $DB_DIR_TARGET/"$backupname"-*-semanal.tar${EXTENSION} 2> /dev/null | awk 'NR>1')
            else
              echo "Clean DIA $backupname"
              rm -f $(/bin/ls -t $DB_DIR_TARGET/"$backupname"-*-dia.tar${EXTENSION} 2> /dev/null | awk 'NR>1')
            fi
          fi
        fi
      done
    fi
  done
  find $BACKUPDIR -name "*-*.tar${EXTENSION}*" -size +0 -exec rm {} \; -exec touch {} \;
fi
backup_target ${DB_DUMP_TARGET_SYNC}