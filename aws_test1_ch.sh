#!/bin/bash

export PATH=$PATH:/usr/local/bin/:/usr/bin
d=`date +%Y-%m-%d`
ownerid=617534363424
i=0

##############################################
#Check Inst. State
##############################################
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId, State.Name, PublicDnsName, LaunchTime, PublicIpAddress, PrivateIpAddress, Placement.AvailabilityZone]' --output text | while read line
do
arr=($(echo $line | tr " " "\n"))
if [ -z ${arr[2]} ]; then 
arr[2]='NULL' 
fi
n=($(aws ec2 describe-instances --instance-id ${arr[0]} --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value]' --output text))
arr[3]=$n
ami_cur=($(aws ec2 describe-images --owners $ownerid --query "Images[?Name=='$n'].ImageId" --output text))
############################################
#create AMI
#Terminate inst.
############################################
desc=$n_$d
if [ ${arr[1]} == 'stopped' ] && [ -z $ami_cur ]; then
aws ec2 create-image --instance-id ${arr[0]} --name $n --description $desc
aws ec2 terminate-instances --instance-ids ${arr[0]}
arr[1]='TERMINATED'
echo ${terminated[*]}
echo "Create new AMI now and terminate stopped instance"
fi
printf '{\n"InstanceId : %s",\n "State : %s",\n "PublicDnsName : %s",\n "LaunchTime : %s",\n "PublicIpAddress : %s",\n "PrivateIpAddress : %s",\n "AvailabilityZone : %s"\n}\n' "${arr[0]}" "${arr[1]^^}" "${arr[2]}" "${arr[3]}" "${arr[4]}" "${arr[5]}" "${arr[6]}"
done 
############################################
#Cleanup up AMIs older than 7 days
############################################
aws ec2 describe-images --owners $ownerid --query 'Images[*].[Name, Description, CreationDate, ImageId]' --output text | while read line
do
arr2=($(echo $line | tr " " "\n"))
ami_d=($(echo ${arr2[2]} | tr "T" "\n")) #
ami_d=($(echo ${arr2[1]} | tr "_" "\n")) # test
age=$((($(date -d "$d" '+%s') - $(date -d "${ami_d[1]}" '+%s'))/86400))
if [ $age -gt 7 ]; then
aws ec2 deregister-image --image-id ${ami_d[3]}
echo 1
fi
done

