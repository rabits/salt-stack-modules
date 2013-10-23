#!/bin/sh
# DNC DIST prepare script
# How to use:
# 1. Create dist directory
#  $ mkdir -p dnc
# 2. Unpack installer 1.2.5 into "dnc" dir
# 3. Unpack with replace updater 1.2.8 into "dnc" dir
# 4. Run prepare_dist.sh in current directory

PREFIX="dist"
INST_DIR="$(dirname "$0")/dnc"

echo "Preparing of ${PREFIX} started..."
mkdir -p "${PREFIX}"
if [ $? -ne 0 ]
then
    echo "Unable to create ${PREFIX} directory" >&2
    exit 1
fi

echo 'Copying config files...'
mkdir -p "${PREFIX}/etc"
cp -vr "${INST_DIR}/etc/dancy" "${PREFIX}/etc"
cp -vr "${INST_DIR}/etc/hwsrv" "${PREFIX}/etc"
mkdir -p "${PREFIX}/tmp/dancy"
mkdir "${PREFIX}/tmp/dancy/upload_log"
mkdir "${PREFIX}/tmp/dancy/unload_log"
mkdir "${PREFIX}/tmp/dancy/postgres_log"
mkdir "${PREFIX}/tmp/dancy/conf"
mkdir -p "${PREFIX}/usr/share/dnc"
cp -vr "${INST_DIR}/movie" "${PREFIX}/usr/share/dnc/"
cp -vr "${INST_DIR}/Example_print_document" "${PREFIX}/usr/share/dnc/print_doc"

for arch in x86 x86_64
do
    case "${arch}" in
        x86_64)
            BIN="${INST_DIR}/bin_64"
            LIBS="${INST_DIR}/libs_64"
            ;;
        *)
            BIN="${INST_DIR}/bin"
            LIBS="${INST_DIR}/libs"
            ;;
    esac

    echo 'Copying programs & scripts ${arch}...'
    mkdir -p "${PREFIX}/usr/bin_${arch}"
    cp -v "${BIN}/Display" "${PREFIX}/usr/bin_${arch}"
    cp -v "${BIN}/RMK" "${PREFIX}/usr/bin_${arch}"
    cp -v "${BIN}/SetupLoadUnload" "${PREFIX}/usr/bin_${arch}"
    cp -v "${BIN}/WareProject" "${PREFIX}/usr/bin_${arch}"
    cp -v "${BIN}/AccessRights" "${PREFIX}/usr/bin_${arch}"
    cp -v "${BIN}/confGUI" "${PREFIX}/usr/bin_${arch}"
    cp -v "${BIN}/daemon_unload" "${PREFIX}/usr/bin_${arch}"
    cp -v "${BIN}/reshka" "${PREFIX}/usr/bin_${arch}"
    cp -v "${BIN}/upload" "${PREFIX}/usr/bin_${arch}"
    cp -v "${BIN}/run_reshka" "${PREFIX}/usr/bin_${arch}"
    cp -v "${BIN}/FindHardPath" "${PREFIX}/usr/bin_${arch}"
    cp -v "${BIN}/dnc_update" "${PREFIX}/usr/bin_${arch}"
    cp -v "${BIN}/update_from_cd" "${PREFIX}/usr/bin_${arch}"
    cp -v "${BIN}/reshkaver" "${PREFIX}/usr/bin_${arch}"
    chmod -R 755 "${PREFIX}/usr/bin_${arch}"

    echo 'Copying libraries ${arch}...'
    cp -rv "${LIBS}" "${PREFIX}/lib_${arch}"
    chmod -R 755 "${PREFIX}/lib_${arch}"
done

cp -v "${INST_DIR}/addon_conf/qtrc" "${PREFIX}/etc/qtrc"

echo "Preparing complete"
