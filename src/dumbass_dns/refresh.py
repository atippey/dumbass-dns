#!/usr/bin/env python3
"""Dynamic DNS driver main"""
from os import getenv

import boto3
import requests

DOMAIN = getenv("DOMAIN")
ZONE_ID = getenv("ZONE_ID")
TTL = int(getenv("TTL", "300"))
TIMEOUT = int(getenv("TIMEOUT", "30"))


def main() -> None:
    """Update target zone id for current ip"""
    # Get current public IP
    current_ip = requests.get("https://api.ipify.org", timeout=TIMEOUT).text

    # Get DNS IP
    client = boto3.client("route53")
    response = client.list_resource_record_sets(
        HostedZoneId=ZONE_ID, StartRecordName=DOMAIN, StartRecordType="A", MaxItems="1"
    )

    dns_ip = response["ResourceRecordSets"][0]["ResourceRecords"][0]["Value"]

    # Update if changed
    if current_ip != dns_ip:
        client.change_resource_record_sets(
            HostedZoneId=ZONE_ID,
            ChangeBatch={
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": DOMAIN,
                            "Type": "A",
                            "TTL": 300,
                            "ResourceRecords": [{"Value": current_ip}],
                        },
                    }
                ]
            },
        )


if __name__ == "__main__":
    main()
