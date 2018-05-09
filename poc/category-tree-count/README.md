# Category tree count

## Goal of this POC

When displaying the category tree in the product grid, the number of products in each category should be displayed.

## Objectives

By defition, we shouldn't do any compromise on our objectives.

Here the list of objectives:

- should be displayed in less than 2 seconds
- support 5000 categories
- in 3 category trees (1666 categories/tree)
- with 130 000 products 
- should support 50 users concurrently

Note: 50 users on the PIM des not mean 50 concurrent requests. Users are not active at the same time.

## Axes 

We can do compromise on axes. Goal is to know: what are the limit of our axes.
It is allowed to put a limit on an axis, if it's possible to reach this limit.
At least, we should document it.

Here the list of axes:

- number of sub-categories in a category

## How it works in 2.2?

![Alt text](category_tree.png?raw=true "Category tree")

### Count in the category tree

When displaying the category tree "master" in the datagrid, it will:
- count the number of products for all the category tree: "master" and "minor" in this example
- count the number of products in category "A" and in category "B"

For the count, a product is considered in a category if it belongs to at least one viewable category in the subtree of this category.

For example, for the count, products viewable in "master" are "1", "2", "3", "5", "7" = 5 products.

Products viewable in "minor" are "2", "6" = 2 products.

Do note that a category can be visible but not its parent. This is important.

### Count in the product datagrid

When displaying the product in the grid, the rule is not the same.
For the datagrid, a product is returned if it belongs to at least one viewable category (but not only in the subtree of this category).

For example, in the datagrid, products viewable in "master" are "1", "2", "3", "5", "7" = 5 products. Same as for the count.
Products viewable in "minor" are "2", "6", "7" = 3 products! Not same as for the count. 

So, the count in the category is different from the count displayed in the datagrid because it does not apply the same rule for the permission.

Functionnal weirdness. PO warned.

## Why it does not scale?

When counting on "master" tree, it counts on "A" and "B".
- first, it gets all categories viewable in "A" with an SQL request.
- then, it gets the count in ES for the category "A" with all viewable categories returned by previous request (potentially several thousands categories)
- then, it gets all categories viewable in "B" with an SQL request.
- then, it gets the count in ES for the category "B" with all viewable categories returned by previous request (potentially several thousands categories)

In this example, it's ok because you don't have a lot of categories in "master".
When you have a lot of categories in "master", it is very slow.

With 5000 categories, 10 000 products, 890 categories at the first level of "master", it takes 7 seconds!
Each SQL request is pretty fast. But there is 890 SQL requests. 
Each ES is fast. But there is 890 ES requests.
And there are 890 requests for the traduction as well (lazy loading...).

So, 4470 SQL requests, and 890 ES requests.

## What are the solutions?

### First one: less requests

Pros:
- less costly implementation
- same behavior as before

Drawback:
- dependent of the total number of categories
- still have big queries in ES, by requesting with all the viewable categories

The solution is to get all the categories of the node and all the viewable categories in it, in one single query. 
Then, we will do one single query in ES, using the multi-search API (taht we should use more!).

#### SQL optimization

After optimization of the SQL request, I got pretty decent results.

```
    CREATE INDEX test_category_access ON pimee_security_product_category_access (view_items, user_group_id);
    CREATE INDEX test_category ON pim_catalog_category (lft, rgt);

    SELECT c.child_code, GROUP_CONCAT(c.subchild_code) FROM (
        SELECT child.code as child_code,  subchild.code as subchild_code
        FROM pim_catalog_category parent
        JOIN pim_catalog_category child on child.parent_id = parent.id
        JOIN pim_catalog_category subchild on subchild.lft BETWEEN child.lft AND child.rgt AND subchild.root = child.root
        JOIN pimee_security_product_category_access ca on ca.category_id = subchild.id 
        WHERE parent.code = 'master'
        AND ca.user_group_id IN (1, 4)
        AND ca.view_items = 1 ) as c
    GROUP BY c.child_code;
```

It takes 50 ms to return 890 categories, with all their viewable node associated (in a list separated by ",", see GROUP_CONCAT operator).

Let's test it concurrently on a server with 12 cores:

```
mysqlslap --create-schema akeneo_pim --concurrency=12 --iterations=20 -u akeneo_pim -pakeneo_pim --query=/var/tmp/query.sql
```

It takes 84ms to execute the request with 12 concurrent query.

```
mysqlslap --create-schema akeneo_pim --concurrency=24 --iterations=20 -u akeneo_pim -pakeneo_pim --query=/var/tmp/query.sql
```

It takes 152ms to execute the request with 24 concurrent query.

Almost the double: it's normal. We have 12 cores. Mysql execute each request on a core. So, it does not really scale more than 12 concurrent requests without impacting the response time.

#### ES optimization

We do a multi-search:
```
    { "index" : "akeneo_pim_product"}
    {"size":0, "query" : {"constant_score": {"filter": {"terms": { "categories" : ["0010692373450"]}}}}}
    { "index" : "akeneo_pim_product"}
    {"size":0, "query" : {"constant_score": {"filter": {"terms": { "categories" : ["0028639452243"]}}}}}
    { "index" : "akeneo_pim_product"}
```

For the ES part, the response time is 384ms. 
I didn't test the scalability of ES. I don't worry about it. ES can, more or less, scale as much as we want (not the case of Mysql without using Mysql cluster).

So, in term of IO, we have the result in less than 500ms. Meaning that we can have the result in 700ms (loading of the kernel, authentication, etc).


Note: 890 direct children in one category is very probably an edge case. So, for most of the cases, we should have far better results. Meaning that we could have a response time in 500 ms very probably.

#### Conclusion

For me, this POC is OK. But we will still have big requests with `IN (viewable_category, etc)`. It's time consuming both in Mysql in ES. It could be avoided by the second solution.

### Second one: request all products in a node

Pros:
- no big request in Mysql 
- no big request with all viewable categories in ES
- probably scale with several millions of products without any problem

Cons:
- functionnal edge case prevent it (due to permissions)

With ES, it's possible to request all data in a node by configuring the indexation.
The idea is to index products with the full path "master/A/B". Then, ES is able to split it and index the product has being part of "master", "master/A", "master/A/B".

Then it would very easy to search how many product there are in each category:
```
{ "index" : "poc_categories"}
{"size":0, "query" : {"constant_score": {"filter": {"term": { "categories" : "node_2/node_10/node_1"}}}}}
{ "index" : "poc_categories"}
{"size":0, "query" : {"constant_score": {"filter": {"term": { "categories" : "node_2/node_9/node_4"}}}}}
```

I tested with very simple document, and the count is very fast with 10 millions of products (200ms with multi-search on 1000 categories). 
We could completly ignore a part of tree that is no authorized quite easily in the request (it would add an overhead, not tested, but I don't worry about it).

I didn't do more research on this solution.

_Do note that a category can be visible but not its parent. This is important._

Actually, this particular case prevent us to to ignore a part of the tree. We have to manage each category individually for th pemrissions.

We are curretly investigating if it's really useful.

