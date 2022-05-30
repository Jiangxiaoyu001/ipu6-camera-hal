#!/bin/bash
set -e

function usage() {
    printf "gen_release.sh --help\n"
    printf " --camera_repo=<absolute_path_to_camera_repo>\n"
    printf " --target=<build_target>\n"
}

if [[ $# -lt 2 ]]; then
    usage
    exit 1
fi

for arg in "$@"; do
    case ${arg} in
        --camera_repo=*)
            repo_path="${arg#*=}"
            shift
            ;;
        --target=*)
            target_name="${arg#*=}"
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 0
            ;;
    esac
done

IPU6REL4GITHUB_CLEAN_CAMERA_REPO=${repo_path}
IPU6REL4GITHUB_BUILT_OUTPUT_DIR=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/out
IPU6REL4GITHUB_PREPARE_CODE_DIR=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/prepared_rel4github
TARGET_NAME=${target_name}
EXECPATH=$PWD

#setting files per target
if [[ ${TARGET_NAME} == "tgl-iotg" ]];then
    FIRMWARE_DIR=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/firmware/ipu6/Productsigned/
    FIRMWARE_NAME=ipu6_fw.bin

    HAL_CODE_CLEAN_CFG_NAME=exclude_conf_tgl_iotg.json

    LIBIPU_A=libipu6.a
    LIBIPU_PKG_CONFIG=libipu6.pc
    LIBIA_P2P_IPU_A=libia_p2p_ipu6.a
    AIQB_SRC=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/imaging-control/tunings/aiqb/TGL/
    AIQB_DST=${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/config/tgl

    KERNEL_VER_CODE=5.14
    DRIVERS_STRIP_DIR=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/drivers/scripts/strip/ipu6_linux/
#################################
elif [[ ${TARGET_NAME} == "tgl-ubuntu" ]];then
    FIRMWARE_DIR=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/firmware/ipu6/Productsigned/
    FIRMWARE_NAME=ipu6_fw.bin

    HAL_CODE_CLEAN_CFG_NAME=exclude_conf_linux.json

    LIBIPU_A=libipu6.a
    LIBIPU_PKG_CONFIG=libipu6.pc
    LIBIA_P2P_IPU_A=libia_p2p_ipu6.a
    AIQB_SRC=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/imaging-control/tunings/aiqb/ubuntu/Andrews/*
    AIQB_DST=${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/config/ubuntu/tgl

    KERNEL_VER_CODE=5.14
    DRIVERS_STRIP_DIR=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/drivers/scripts/strip/ipu6_ipu6ep_ubuntu/
elif [[ ${TARGET_NAME} == "ccg-platform" ]];then
    FIRMWARE_DIR=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/firmware/ipu6ep/Productsigned/
    FIRMWARE_NAME=ipu6ep_fw.bin

    HAL_CODE_CLEAN_CFG_NAME=exclude_conf_adl_ccg_plat.json

    LIBIPU_A=libipu6ep.a
    LIBIPU_PKG_CONFIG=libipu6ep.pc
    LIBIA_P2P_IPU_A=libia_p2p_ipu6ep.a
    AIQB_SRC=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/imaging-control/tunings/aiqb/chrome/adlrvp/ov8856.aiqb
    AIQB_DST=${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/config/ubuntu/adl

    KERNEL_VER_CODE=5.15
    DRIVERS_STRIP_DIR=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/drivers/scripts/strip/ipu6_linux/ccg_plat/
elif [[ ${TARGET_NAME} == "ccg-cce-tributo" ]];then
    FIRMWARE_DIR=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/firmware/ipu6ep/Productsigned/
    FIRMWARE_NAME=ipu6ep_fw.bin

    HAL_CODE_CLEAN_CFG_NAME=exclude_conf_adl_ccg_cce_tributo.json

    LIBIPU_A=libipu6ep.a
    LIBIPU_PKG_CONFIG=libipu6ep.pc
    LIBIA_P2P_IPU_A=libia_p2p_ipu6ep.a
    AIQB_SRC=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/imaging-control/tunings/aiqb/ADL/ov01a_SB2_ADL.aiqb
    AIQB_DST=${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/config/ubuntu/adl/ov01a10.aiqb

    KERNEL_VER_CODE=5.14
    DRIVERS_STRIP_DIR=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/drivers/scripts/strip/ipu6_ipu6ep_ubuntu/
elif [[ ${TARGET_NAME} == "ccg-jsl-edu" ]];then
    FIRMWARE_DIR=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/firmware/ipu6se/Productsigned/
    FIRMWARE_NAME=ipu6se_fw.bin

    HAL_CODE_CLEAN_CFG_NAME=exclude_conf_jsl_ccg_edu.json

    LIBIPU_A=libipu6sepla.a
    LIBIPU_PKG_CONFIG=libipu6sepla.pc
    LIBIA_P2P_IPU_A=libia_p2p_ipu6sepla.a
    AIQB_SRC=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/imaging-control/tunings/aiqb/JSL/OV13858_YHCEU_JSLP.aiqb
    AIQB_DST=${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/config/ubuntu/jsl/ov13858.aiqb

    KERNEL_VER_CODE=5.10.46
    DRIVERS_STRIP_DIR=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/drivers/scripts/strip/ipu6_linux/ccg_tencent/
else
    echo "${TARGET_NAME} is unkonwn, please add here"
    exit 1
fi

echo "Are you sure to delete $IPU6REL4GITHUB_PREPARE_CODE_DIR ?"
echo "Enter: yes/no"
read ans
if [ $ans == "yes" ];
then
    if [ -d $IPU6REL4GITHUB_PREPARE_CODE_DIR ];
        then rm -r ${IPU6REL4GITHUB_PREPARE_CODE_DIR};
    fi
else
    exit 0;
fi

echo "You are going to copy source code for ipu6-camera-hal, ipu6-drivers from:"
echo "    $IPU6REL4GITHUB_CLEAN_CAMERA_REPO"
echo "You are going to copy bins for ipu6-camera-bins from:"
echo "    $IPU6REL4GITHUB_BUILT_OUTPUT_DIR"
echo "Make sure you HAVE BUILT camera_repo with settings:"
echo "    ${TARGET_NAME}"
echo "    Release"
echo "Are you going to continue?"
echo "Enter: yes/no"
read ans
if [ $ans == "yes" ];then echo; else exit 0; fi

strip_libcamhal(){
    cd $IPU6REL4GITHUB_CLEAN_CAMERA_REPO/libcamhal/
    git reset --hard $(git rev-parse HEAD) && git clean -xdf
    if [ -d $IPU6REL4GITHUB_CLEAN_CAMERA_REPO/libcamhal/build ]; then rm -r ${CLEAN_CAMERA_REPO}/camera/libcamhal/build; fi
    cd $IPU6REL4GITHUB_CLEAN_CAMERA_REPO/libcamhal/tools/code_cleanup/
    ./clean_code.py ${HAL_CODE_CLEAN_CFG_NAME} && echo
    cd ${IPU6REL4GITHUB_CLEAN_CAMERA_REPO} && echo
}

reset_libcamhal(){
    cd $IPU6REL4GITHUB_CLEAN_CAMERA_REPO/libcamhal/
    git reset --hard $(git rev-parse HEAD) && git clean -xdf
}

standardize_pkg_config_path(){
    if [[ ! -f $1 ]]; then echo "file $1 not exsist."; exit 0; fi
    sed -i '/prefix=/ d' $1
    sed -i '/exec_prefix=/ d' $1
    sed -i '/libdir=/ d' $1
    sed -i '/includedir=/ d' $1
    standard="prefix=/usr\nexec_prefix=/usr\nlibdir=/usr/lib\nincludedir=/usr/include"
    sed -i "1i${standard}" $1
}


bins_ipu6_regenerate(){
    PREFIX_INCLUDE=${IPU6REL4GITHUB_BUILT_OUTPUT_DIR}/${TARGET_NAME}/install/include
    PREFIX_LIB=${IPU6REL4GITHUB_BUILT_OUTPUT_DIR}/${TARGET_NAME}/install/lib
    PKGCONFIG_DIR=${IPU6REL4GITHUB_BUILT_OUTPUT_DIR}/${TARGET_NAME}/install/lib/pkgconfig

#    cd $IPU6REL4GITHUB_CLEAN_CAMERA_REPO/
#    source build-dev/env.sh --release
#    lunch ${TARGET_NAME}
#    strip_libcamhal
#    mmm -j8
    mkdir -p ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/include
    mkdir -p ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/include/ia_camera
    mkdir -p ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/include/ia_tools
    mkdir -p ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/include/ia_imaging
    mkdir -p ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/include/ia_cipf
    mkdir -p ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/include/ia_cipf_css


    echo "prepare headers..."
    # TODO(chongyang) reduce redudant headers and .so ?
    ia_camera_headers=(
        gcss_aic_utils.h \
        gcss.h \
        gcss_isp_utils.h \
        gcss_item.h \
        gcss_keys.h \
        GCSSParser.h \
        gcss_utils.h \
        graph_query_manager.h \
        graph_utils.h \
        ipu_process_group_wrapper.h
    )
    for f in ${ia_camera_headers[*]}
    do
        cp $PREFIX_INCLUDE/ia_camera/${f} ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/include/ia_camera/${f}
    done

    ia_tools_header=(
        ia_list.h \
        css_types.h
    )
    for f in ${ia_tools_header[*]}
    do
        cp $PREFIX_INCLUDE/ia_tools/${f} ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/include/ia_tools/${f}
    done

    ia_imaging_header=(
        CCAMacro.h \
        CCAStorage.h \
        ia_abstraction.h \
        ia_aec_types.h \
        ia_aiq_deprecated.h \
        ia_aiq.h \
        ia_aiq_types_deprecated.h \
        ia_aiq_types.h \
        ia_bcomp.h \
        ia_bcomp_types.h \
        ia_ccat_types.h \
        ia_cmc_parser_deprecated.h \
        ia_cmc_parser.h \
        ia_cmc_types.h \
        ia_configuration.h \
        ia_dvs_deprecated.h \
        ia_dvs.h \
        ia_dvs_types.h \
        ia_isp_bxt_deprecated.h \
        ia_isp_bxt.h \
        ia_isp_bxt_statistics_types.h \
        ia_isp_bxt_types.h \
        ia_isp_types.h \
        ia_lard.h \
        ia_log.h \
        ia_ltm_deprecated.h \
        ia_ltm.h \
        ia_ltm_types.h \
        ia_misra_types.h \
        ia_mkn_encoder.h \
        ia_mkn_types.h \
        ia_nvm.h \
        ia_ob.h \
        ia_p2p.h \
        ia_p2p_types.h \
        ia_pal_types_isp.h \
        ia_pal_types_isp_ids_autogen.h \
        ia_pal_types_isp_parameters_autogen.h \
        ia_statistics_types.h \
        ia_types.h \
        ia_view.h \
        ia_view_types.h \
        IIPUAic.h \
        IntelCCA.h \
        IntelCCATypes.h
    )
    for f in ${ia_imaging_header[*]}
    do
        cp $PREFIX_INCLUDE/ia_imaging/${f} ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/include/ia_imaging/${f}
    done

    cp $PREFIX_INCLUDE/ia_cipf/ia_cipf_types.h ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/include/ia_cipf/ia_cipf_types.h
    cp $PREFIX_INCLUDE/ia_cipf_css/ia_cipf_css.h ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/include/ia_cipf_css/ia_cipf_css.h
    echo "prepare libs..."
    mkdir  -p ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/lib/firmware/intel
    mkdir  -p ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/lib/pkgconfig
    so_files=(
        ${LIBIA_P2P_IPU_A} \
        ${LIBIPU_A} \
        libbroxton_ia_pal.so \
        libgcss.so \
        libgcss.so.0 \
        libgcss.so.0.0.0 \
        libia_aiqb_parser.so \
        libia_aiq.so \
        libia_bcomp.so \
        libia_cca.so \
        libia_cmc_parser.so \
        libia_coordinate.so \
        libia_dvs.so \
        libia_exc.so \
        libia_isp_bxt.so \
        libia_lard.so \
        libia_log.so \
        libia_ltm.so \
        libia_mkn.so \
        libia_nvm.so
    )
    # hal/icamerasrc compiling link issue to libia_cipf.so

    for f in ${so_files[*]}
    do
        cp -P $PREFIX_LIB/${f} ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/lib/${f}
    done

    cp ${FIRMWARE_DIR}/${FIRMWARE_NAME} ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/lib/firmware/intel/${FIRMWARE_NAME}

    echo "copying pkgconfig files..."
    cp ${PKGCONFIG_DIR}/ia_imaging.pc ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/lib/pkgconfig/
    cp ${PKGCONFIG_DIR}/libgcss.pc ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/lib/pkgconfig/
    cp ${PKGCONFIG_DIR}/libiacss.pc ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/lib/pkgconfig/
    cp ${PKGCONFIG_DIR}/${LIBIPU_PKG_CONFIG} ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/lib/pkgconfig/
    echo "standardizing pkgconfig files..."
    standardize_pkg_config_path ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/lib/pkgconfig/ia_imaging.pc
    standardize_pkg_config_path ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/lib/pkgconfig/libgcss.pc
    standardize_pkg_config_path ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/lib/pkgconfig/${LIBIPU_PKG_CONFIG}

    ##################### move ipu6-camera-bins/ into ipu6-camera-bins/ipu6
    TGL_IPU6_CAMERA_BIN_RELEASE=${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/ipu6
    mkdir ${TGL_IPU6_CAMERA_BIN_RELEASE}
    cd ${TGL_IPU6_CAMERA_BIN_RELEASE}
    mv ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/lib ${TGL_IPU6_CAMERA_BIN_RELEASE}
    mv ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-bins/include ${TGL_IPU6_CAMERA_BIN_RELEASE}
    cd -
    echo "====================================="
    echo "prepare ipu6-camera-bins  finished!!! "
    echo "====================================="
}

drivers_ipu6_regen(){
    mkdir ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-drivers/
    cd ${DRIVERS_STRIP_DIR}
    export PATH=${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/drivers/scripts/strip/:$PATH
    EXTERNAL_BUILD=1 KERNEL_VER=${KERNEL_VER_CODE} ./strip_code.sh ${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/drivers/ ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-drivers/
    echo "====================================="
    echo "  prepare ipu6-drivers  finished!!!  "
    echo "====================================="
}

hal_ipu6_regenerate(){
    echo "Is libcamhal clean and no private branches?"
    echo "Enter: yes/no"
    read ans
    if [ $ans == "yes" ];then echo; else exit 0; fi
    mkdir ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/
    #cp -rf ${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/libcamhal/README.md ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/
    strip_libcamhal;
    echo "====================================="
    ls ${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/libcamhal/config/*
    echo "==================================>>>>>>>>>>>>>>>>>>>>>>"
    IPU6_BUILDLINK_PCKCONFIGPATH=${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/ipu6-camera-bins
    mkdir ${IPU6_BUILDLINK_PCKCONFIGPATH}
    cp -rf ${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/libcamhal/* ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/
    #### cpoying camera-libs to camera-hal ,build and link libcamhal rpm
    cp -rf ${IPU6REL4GITHUB_BUILT_OUTPUT_DIR}/${TARGET_NAME}/install/* ${IPU6_BUILDLINK_PCKCONFIGPATH}

    ####### single build and install libcamhal rpm not required install aiqb ######
    #echo "copying ${AIQB_SRC} into ${AIQB_DST}..."
    #cp -rf ${AIQB_SRC} ${AIQB_DST}

    reset_libcamhal;

    echo "cleaning... ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/"
    if [[ -d ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/.git ]]; then rm -r ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/.git ; fi
    if [[ -f ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/.gitignore ]]; then rm ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/.gitignore ; fi
    if [[ -f ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/.clang-format ]]; then rm ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/.clang-format ; fi
    if [[ -d ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/test ]]; then rm -r ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/test ; fi
    if [[ -d ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/tools ]]; then rm -r ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/tools ; fi

    # TODO(chongyang) ? following is a strip for gitub, do the strip here or
    #  create another ./clean_code.py exclude_conf_linux.json
    echo "warning: clean hard code 5 lines for CMakeLists.txt "
    sed -i '/BUILD_CAMHAL_TESTS/d' ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/CMakeLists.txt
    sed -i '/BUILD_TESTS_S/I,+5 d' ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/CMakeLists.txt

    # hal config file destination on github has changed
    # no need, will be delete in later
    if [[ ${TARGET_NAME} == "tgl-ubuntu" ]];then
        mv ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/config/ubuntu/tgl ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/config/linux/ipu6
        rm -r ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/config/ubuntu
    elif [[ ${TARGET_NAME} == "ccg-cce-tributo" ]];then
        mv ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/config/ubuntu/adl ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/config/linux/ipu6ep
        rm -r ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/config/ubuntu
    fi

    echo
    echo "====================================="
    echo " prepare ipu6-camera-hal finished!!! "
    echo "====================================="
}

function icamerasrc_regen(){
    echo "regenerate icamerasrc for branch icamerasrc_slim_api"
    mkdir ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/icamerasrc/
    cd ${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/icamerasrc/
    git reset --hard $(git rev-parse HEAD) && git clean -xdf
    cd ${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}
    cp -r ${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/icamerasrc/* ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/icamerasrc/
    if [[ -d ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/icamerasrc/test ]]; then rm -r ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/icamerasrc/test ; fi
    if [[ -d ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/icamerasrc/tools ]]; then rm -r ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/icamerasrc/tools ; fi
    if [[ -f ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/icamerasrc/COPYING ]]; then rm -r ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/icamerasrc/COPYING ; fi
    if [[ -f ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/icamerasrc/README ]]; then rm -r ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/icamerasrc/README ; fi
    if [[ -f ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/icamerasrc/README_imx185 ]]; then rm -r ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/icamerasrc/README_imx185 ; fi
    ln -s  README.md  ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/icamerasrc/README
    echo "====================================="
    echo "    prepare icamerasrc  finished!!!  "
    echo "====================================="

}

## customize env.sh to config build and link pkg_config path
regenerate_buildenv(){
	cp -rf ${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}/build-dev/env.sh ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/ipu6-camera-hal/
}

mkdir ${IPU6REL4GITHUB_PREPARE_CODE_DIR}
cd ${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}
repo manifest -r -o ${IPU6REL4GITHUB_PREPARE_CODE_DIR}/manifest.xml
# repo checkout branch
#repo forall -c 'git checkout tgl_manchester_pv_20210923'
bins_ipu6_regenerate
drivers_ipu6_regen
hal_ipu6_regenerate
#regenerate_buildenv
#icamerasrc_regen
#cd ${EXECPATH} & cp -rf ${IPU6REL4GITHUB_PREPARE_CODE_DIR} ${EXECPATH}/
cp -rf ${IPU6REL4GITHUB_PREPARE_CODE_DIR} ${IPU6REL4GITHUB_CLEAN_CAMERA_REPO}../

echo -e "\e[34m[info]cpoying ${IPU6REL4GITHUB_PREPARE_CODE_DIR} into ${EXECPATH}\e[0m"
echo "====================================="
echo "       prepare code finished!!!      "
echo "====================================="
echo "please find prepared code at ${IPU6REL4GITHUB_PREPARE_CODE_DIR}"
