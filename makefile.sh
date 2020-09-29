#!/bin/sh

echo "Making titles..."
# make time stamp & count blocked
TIME_STAMP=$(date +'%d %b %Y %H:%M')
VERSION=$(date +'%y%m%d%H%M')
LC_NUMERIC="en_US.UTF-8"
DOMAIN=$(printf "%'.3d\n" $(cat source/hosts-group.txt source/hosts-VN-group.txt source/hosts-VN.txt source/hosts.txt source/hosts-extra.txt | grep "0.0.0.0" | wc -l))
DOMAIN_VN=$(printf "%'.3d\n" $(cat source/hosts-VN-group.txt source/hosts-VN.txt | grep "0.0.0.0" | wc -l))
DOMAIN_GA=$(printf "%'.3d\n" $(cat source/hosts-gambling.txt | grep "0.0.0.0" | wc -l))
RULE=$(printf "%'.3d\n" $(cat source/adservers.txt source/adservers-all.txt source/adservers-extra.txt source/exceptions.txt | grep -v '!' | wc -l))
RULE_VN=$(printf "%'.3d\n" $(cat source/adservers.txt | grep -v '!' | wc -l))

# update titles
sed -e "s/_time_stamp_/$TIME_STAMP/g" -e "s/_version_/$VERSION/g" -e "s/_domain_/$DOMAIN/g" tmp/title-hosts.txt > tmp/title-hosts.tmp
sed -e "s/_time_stamp_/$TIME_STAMP/g" -e "s/_version_/$VERSION/g" -e "s/_domain_/$DOMAIN/g" tmp/title-hosts-iOS.txt > tmp/title-hosts-iOS.tmp
sed -e "s/_time_stamp_/$TIME_STAMP/g" -e "s/_version_/$VERSION/g" -e "s/_domain_vn_/$DOMAIN_VN/g" tmp/title-hosts-VN.txt > tmp/title-hosts-VN.tmp
sed -e "s/_time_stamp_/$TIME_STAMP/g" -e "s/_version_/$VERSION/g" -e "s/_domain_ga_/$DOMAIN_GA/g" tmp/title-hosts-gambling.txt > tmp/title-hosts-gambling.tmp
sed -e "s/_time_stamp_/$TIME_STAMP/g" -e "s/_version_/$VERSION/g" -e "s/_rule_/$RULE/g" tmp/title-adserver-all.txt > tmp/title-adserver-all.tmp
sed -e "s/_time_stamp_/$TIME_STAMP/g" -e "s/_version_/$VERSION/g" -e "s/_rule_vn_/$RULE_VN/g" tmp/title-adserver.txt > tmp/title-adserver.tmp
sed -e "s/_time_stamp_/$TIME_STAMP/g" -e "s/_version_/$VERSION/g" -e "s/_rule_/$RULE/g" tmp/title-domain.txt > tmp/title-domain.tmp

echo "Creating hosts file..."
# create hosts files
cat tmp/title-hosts.tmp source/hosts-group.txt source/hosts-VN-group.txt source/hosts-VN.txt source/hosts.txt source/hosts-extra.txt > hosts
cat tmp/title-hosts-VN.tmp source/hosts-VN-group.txt source/hosts-VN.txt > option/hosts-VN
cat tmp/title-hosts-gambling.tmp source/hosts-gambling.txt > option/hosts-gambling

# create hosts-iOS file
cat hosts | grep -v '#' | grep -v -e '^[[:space:]]*$' | awk '{print "0 "$2}' >> tmp/hosts-iOS.tmp
cat tmp/title-hosts-iOS.tmp tmp/hosts-iOS.tmp > option/hosts-iOS

# create domain file
cat hosts | grep -v '#' | grep -v -e '^[[:space:]]*$' | awk '{print $2}' > option/domain.txt

echo "Creating adserver file..."
# create temp adserver files
cat source/adservers.txt | grep -v '!' | awk '{print $1}' >> tmp/adservers.tmp
cat source/adservers-all.txt | grep -v '!' |awk '{print $1}' >> tmp/adservers-all.tmp
cat source/adservers-extra.txt | grep -v '!' |awk '{print $1}' >> tmp/adservers-extra.tmp
cat source/exceptions.txt | grep -v '!' |awk '{print $1}' >> tmp/exceptions.tmp

# create adserver files
cat tmp/adservers.tmp | awk '{print "||"$1"^"}' >> tmp/adservers-rule.tmp
cat tmp/adservers.tmp tmp/adservers-all.tmp tmp/adservers-extra.tmp | awk '{print "||"$1"^"}' >> tmp/adservers-all-rule.tmp
cat tmp/exceptions.tmp | awk '{print "@@||"$1"^|"}' >> tmp/adservers-all-rule.tmp
cat tmp/adservers.tmp tmp/adservers-all.tmp | awk '{print "*"$1" = 0.0.0.0"}' >> tmp/adservers-config.tmp

echo "Creating rule file..."
# create rule
cat source/config-rule.txt | awk '{print "HOST-KEYWORD,"$1",REJECT"}' > option/hostsVN-quantumult-rule.conf
cat tmp/adservers.tmp tmp/adservers-all.tmp | awk '{print "HOST-SUFFIX,"$1",REJECT"}' >> option/hostsVN-quantumult-rule.conf
cat source/config-rule.txt | awk '{print "DOMAIN-KEYWORD,"$1}' > option/hostsVN-surge-rule.conf
cat tmp/adservers.tmp tmp/adservers-all.tmp | awk '{print "DOMAIN-SUFFIX,"$1}' >> option/hostsVN-surge-rule.conf
cat source/config-rule.txt | awk '{print "DOMAIN-KEYWORD,"$1",REJECT"}' > tmp/shadowrocket-rule.tmp
cat tmp/adservers.tmp tmp/adservers-all.tmp | awk '{print "DOMAIN-SUFFIX,"$1",REJECT"}' >> tmp/shadowrocket-rule.tmp

# create exceptions rule
cat tmp/exceptions.tmp | awk '{print "HOST,"$1",DIRECT"}' > option/hostsVN-quantumult-exceptions-rule.conf
cat tmp/exceptions.tmp | awk '{print "DOMAIN,"$1}' > option/hostsVN-surge-exceptions-rule.conf
cat tmp/exceptions.tmp | awk '{print "DOMAIN,"$1",DIRECT"}' >> tmp/shadowrocket-exceptions-rule.tmp

echo "Creating rewrite file..."
# create rewrite
cat source/config-rewrite.txt | grep -v '#' | grep -v -e '^[[:space:]]*$' | awk '{print $1}' > option/hostsVN-quantumult-rejection.conf
cat source/config-rewrite.txt | grep -v '#' | grep -v -e '^[[:space:]]*$' | awk '{print $1" reject"}' > tmp/rewrite-shadowrocket.tmp
cat source/config-rewrite.txt | grep -v '#' | grep -v -e '^[[:space:]]*$' | awk '{print "URL-REGEX,"$1}' > option/hostsVN-surge-rewrite.conf
cat source/config-hostname.txt > option/hostsVN-quantumultX-rewrite.conf
cat source/config-rewrite.txt | grep -v '#' | grep -v -e '^[[:space:]]*$' | awk '{print $1" url reject-img"}' >> option/hostsVN-quantumultX-rewrite.conf

echo "Creating config file..."
# create config
HOSTNAME=$(cat source/config-hostname.txt)
sed -e "s/!_hostname_/$HOSTNAME/g" tmp/title-config-surge.txt > tmp/title-config-surge.tmp
sed -e "s/!_hostname_/$HOSTNAME/g" tmp/title-config-surge.txt | grep -v '#' > option/hostsVN-surge-pro.conf
sed -e "s/_time_stamp_/$TIME_STAMP/g" tmp/title-config-quantumultX.txt > option/hostsVN-quantumultX.conf
sed -e "s/!_hostname_/$HOSTNAME/g" -e '/!_rejection_quantumult_/r option/hostsVN-quantumult-rejection.conf' -e '/!_rejection_quantumult_/d' -e '/!_rule_quantumult_/r option/hostsVN-quantumult-rule.conf' -e '/!_rule_quantumult_/d' -e '/!_rule_exceptions_quantumult_/r option/hostsVN-quantumult-exceptions-rule.conf' -e '/!_rule_exceptions_quantumult_/d' tmp/title-config-quantumult.txt > option/hostsVN-quantumult.conf
sed -e "s/!_hostname_/$HOSTNAME/g" -e '/!_rewrite_shadowrocket_/r tmp/rewrite-shadowrocket.tmp' -e '/!_rewrite_shadowrocket_/d' -e '/!_rule_shadowrocket_/r tmp/shadowrocket-rule.tmp' -e '/!_rule_shadowrocket_/d' -e '/!_rule_exceptions_shadowrocket_/r tmp/shadowrocket-exceptions-rule.tmp' -e '/!_rule_exceptions_shadowrocket_/d' tmp/title-config-shadowrocket.txt > option/hostsVN-shadowrocket.conf

echo "Adding to file..."
# add to files
cat tmp/title-adserver.tmp tmp/adservers-rule.tmp > filters/adservers.txt
cat tmp/title-adserver-all.tmp tmp/adservers-all-rule.tmp > filters/adservers-all.txt
cat tmp/title-domain.tmp tmp/adservers.tmp tmp/adservers-all.tmp tmp/adservers-extra.tmp > filters/domain-adservers-all.txt
cat tmp/title-config-surge.tmp tmp/adservers-config.tmp > option/hostsVN.conf

echo "Creating block OTA file..."
cat source/OTA.txt | grep -v '!' | awk '{print "HOST-SUFFIX,"$1",REJECT"}' > option/hostsVN-quantumult-OTA.conf
cat source/OTA.txt | grep -v '!' | awk '{print "DOMAIN-SUFFIX,"$1}' > option/hostsVN-surge-OTA.conf

# remove tmp file
rm -rf tmp/*.tmp

# check duplicate
echo "Checking duplicate..."
sort option/domain.txt | uniq -d
sort filters/adservers-all.txt | uniq -d
read -p "Completed! Press enter to close"
