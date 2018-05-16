# Proof of concept to improve category research

## Test the number maximum of categories in ES query

```
 export NUMBER_TREE=4
 export TREE_DEPTH=4
 export NUMBER_CHILDREN_PER_CATEGORY=12
 export NUMBER_PRODUCTS=100000
 export NUMBER_CATEGORY_PER_PRODUCT=5
 export ES_REQUEST_DIRECTORY=/var/tmp/poc
 chmod +x ./generate_and_load.sh
 ./generate_and_load.sh
```




        "name": [
            {
                "locale": null,
                "scope": null,
                "data": "Akeneo Sticker"
            }
        ],
        "price": [
            {
                "locale": null,
                "scope": null,
                "data": [
                    {
                        "amount": "2.00",
                        "currency": "EUR"
                    },
                    {
                        "amount": "3.00",
                        "currency": "USD"
                    }
                ]
            }
        ]
