#!/bin/bash
#Modificado el 14/06
dir_user="/userDIR"
dir="/etc/adm-lite"

fun_ip () {
MEU_IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
MEU_IP2=$(wget -qO- ipv4.icanhazip.com)
[[ "$MEU_IP" != "$MEU_IP2" ]] && echo "$MEU_IP2" || echo "$MEU_IP"
}
removeonline(){
i=1
    [[ -d /var/www/html ]] && [[ -e /var/www/html/$arquivo_move ]] && rm -rf /var/www/html/$arquivo_move > /dev/null 2>&1
    [[ -e /var/www/$arquivo_move ]] && rm -rf /var/www/$arquivo_move > /dev/null 2>&1
    echo -e "${cor[5]}Extraxion Exitosa Exitosa"
    echo -e "$barra"
echo "SUBIENDO"
subironline
}   
subironline(){
[ ! -d /var ] && mkdir /var
[ ! -d /var/www ] && mkdir /var/www
[ ! -d /var/www/html ] && mkdir /var/www/html
[ ! -e /var/www/html/index.html ] && touch /var/www/html/index.html
[ ! -e /var/www/index.html ] && touch /var/www/index.html
chmod -R 755 /var/www
cp $HOME/$arquivo_move /var/www/$arquivo_move
cp $HOME/$arquivo_move /var/www/html/$arquivo_move
service apache2 restart
IP="$(fun_ip)"
echo -e "\033[1;36m http://$IP:81/$arquivo_move\033[0m"
echo -e "$barra"
echo -e "${cor[5]}Carga Exitosa!"
echo -e "$barra"
read -p "PRESIONE ENTER"
}


echo -e "\033[1;33mMenu de Respaldos de Usuarios\033[1;30m
----------------------------------
 \033[1;32m1) \033[1;37mCrear respaldo de Usuarios Online
 ----------------------------------
 \033[1;32m2) \033[1;37mRestaurar Usuarios de un backup Online
 ----------------------------------"
read -p "ECOJE: " option
function backup_de_usuarios(){
echo -e "--------------------------------------------------------"
read -p "Ingrese Nombre de su Fichero o pulse ENTER: " name
bc="$HOME/$name"
arquivo_move="$name"
clear
i=1
[[ -e $bc ]] && rm $bc
echo -e "\033[1;37mHaciendo Backup de Usuarios...\033[0m"
for user in `awk -F : '$3 > 900 { print $1 }' /etc/passwd |grep -v "nobody" |grep -vi polkitd |grep -vi systemd-[a-z] |grep -vi systemd-[0-9] |sort`
do
if [ -e $dir$dir_user/$user ]
then
pass=$(cat $dir$dir_user/$user | grep "senha" | awk '{print $2}')
limite=$(cat $dir$dir_user/$user | grep "limite" | awk '{print $2}')
data=$(cat $dir$dir_user/$user | grep "data" | awk '{print $2}')
data_sec=$(date +%s)
data_user=$(chage -l "$user" |grep -i co |awk -F ":" '{print $2}')
data_user_sec=$(date +%s --date="$data_user")
variavel_soma=$(($data_user_sec - $data_sec))
dias_use=$(($variavel_soma / 86400))
if [[ "$dias_use" -le 0 ]]; 
then
dias_use=0
fi
sl=$((dias_use + 1))
i=$((i + 1))
 if [ -z "$limite" ]; then
 limite="5"
 fi
else
echo -e "\033[1;31mNo fue posible obtener la contraseña del usuario\033[1;37m ($user)"
read -p "Introduzca la contraseña manualmente o pulse ENTER: " pass
 if [ -z "$pass" ]; then
pass="$user"
 fi
fi
echo "$user:$pass:$limite:$sl" >> $bc
echo -e "\033[1;37mUser $user Backup [\033[1;31mOK\033[1;37m]\033[0m"
done
echo " "
echo -e "\033[1;31mBackup Completado !!!\033[0m"
echo " "
echo -e "\033[1;37mLa informacion de los usuarios $i se encuentra en el archivo \033[1;31m $bc \033[1;37m"
}
function restaurar_usuarios(){
cd $HOME
echo -n "INGRESE LINK Que Mantienes Online en GitHub, o VPS \n" 
read -p "Pega tu Link : " url1
wget -q -O recovery $url1 && echo -e "\033[1;31m- \033[1;32mFile Exito!" || echo -e "\033[1;31m- \033[1;31mFile Fallo"
#echo -n "Escriba el directorio del archivo Backup: "
echo -e "\033[1;37mRestaurando Usuarios...\033[0m"
[[ -e $HOME/recovery ]] && arq="$HOME/recovery" || return 	
for user in `cat $arq`
do
usuario=$(echo "$user" |awk -F : '{print $1}')
senha=$(echo "$user" |awk -F : '{print $2}')
limite=$(echo "$user" |awk -F : '{print $3}')
data=$(echo "$user" |awk -F : '{print $4}')

valid=$(date '+%C%y-%m-%d' -d " +$data days")
datexp=$(date "+%d/%m/%Y" -d " +$data days")
if cat /etc/passwd |grep $usuario: 1> /dev/null 2>/dev/null
then
echo -e "\033[1;37m\033[1;31m$usuario \033[1;37mEXISTE: \033[1;31m$senha  [\033[1;31mFAILED\033[1;37m]\033[0m" > /dev/null
else
echo "$user" |cut -d: -f3 1> /dev/null 2>/dev/null
  if [ $? = 0 ]
  then
  useradd -M -s /bin/false $usuario
  (echo $senha ; echo $senha) | passwd $usuario > /dev/null 2> /dev/null
  limit $usuario $limite 1> /dev/null 2> /dev/null
  echo "senha: $senha" > /etc/adm-lite/userDIR/$usuario
  echo "limite: $limite" >> /etc/adm-lite/userDIR/$usuario
  echo "data: $valid" >> /etc/adm-lite/userDIR/$usuario
  chage -E $valid $usuario 2> /dev/null
  else
  useradd -M -s /bin/false $usuario
  (echo $senha ; echo $senha) | passwd $usuario > /dev/null 2> /dev/null
  echo "senha: $senha" > /etc/adm-lite/userDIR/$usuario
  echo "limite: $limite" >> /etc/adm-lite/userDIR/$usuario
  chage -E $valid $usuario 2> /dev/null  
  fi
  echo -e "\033[1;31m$usuario \033[1;37mRESTORE: \033[1;31m$senha [\033[1;31mOk\033[1;37m] \033[1;37mcon\033[1;31m $data \033[1;37m Dias\033[0m"
fi
done
}
if [ $option -eq 1 ]; then
backup_de_usuarios
echo -e "-------------------------------------------------------"
echo -e "		\033[4;31mNOTA importante\033[0m"
echo -e "Recuerda Ir a GitHub y cargarlo Online, para luego poder Restaurarlo!!"
echo -e "-------------------------------------------------------"
echo -e " \033[0;31mSi esta usando maquina, Montalo Online"
echo -e "  Para luego usar el Link del Fichero, y puedas ."
echo -e " Descargarlo desde cualquier sitio con acceso WEB"
echo -e "    Ejemplo : http://ip-del-vps:81/tu-fichero.\033[0m"
echo -e "-------------------------------------------------------"
read -p "PRESIONA ENTER PARA CARGAR ONLINE"
removeonline
fi

if [ $option -eq 2 ]; then
restaurar_usuarios
fi