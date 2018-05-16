<?php

$numberTree = getenv('NUMBER_TREE');
$treeDepth = getenv('TREE_DEPTH');
$numberChildrenPerCategory = getenv('NUMBER_CHILDREN_PER_CATEGORY');
$numberProducts = getenv('NUMBER_PRODUCTS');
$numberCategoryPerProduct = getenv('NUMBER_CATEGORY_PER_PRODUCT');
$esRequestsDirectory = getenv('ES_REQUESTS_DIRECTORY');

if (!file_exists($esRequestsDirectory)) {
    mkdir($esRequestsDirectory, 0777, true);
}

$categories = [];
$categoriesPerDepth = [];

$categoriesPerDepth[0] = [];
foreach (range(1, $numberTree) as $rank) {
    $path = 'node_' . $rank;
    $categories[$path] = $path;
    $categoriesPerDepth[0][] = $path;
}

foreach (range(1, $treeDepth) as $depth) {
    $parentCategories = $categoriesPerDepth[$depth - 1];
    $categoriesPerDepth[$depth] = [];

    foreach ($parentCategories as $parentCategory) {
        foreach (range(1, $numberChildrenPerCategory) as $rank) {
            $path = $parentCategory . '/node_' . $rank;
            $categories[$path] = $path;
            $categoriesPerDepth[$depth][] = $path;
        }
    }
}

$countCategories = count($categories);
echo sprintf('%s paths of category created.', $countCategories) . PHP_EOL;

$body = '';
$batchNumber = 0;

for ($i = 0; $i < $numberProducts; $i++) {
    $productCategories = array_rand($categories, $numberCategoryPerProduct);
    $productCategoriesImploded = '"' . implode('","', $productCategories) . '"';

    $body .= <<<REQUEST
    { "create" : { "_index" : "poc_categories", "_type" : "doc", "_id" : "${i}" } }
    { "categories" : [${productCategoriesImploded}] }
    
REQUEST;

    if (($i + 1) % 50000 === 0) {
        file_put_contents(sprintf('%s/es_categories_%s.txt', $esRequestsDirectory, $batchNumber), $body);

        $body = '';
        $batchNumber++;
    }
}

file_put_contents(sprintf('%s/es_categories_%s.txt', $esRequestsDirectory, $batchNumber), $body);


foreach(range(100, 100000, 100) as $numberCategoriesInSelect) {
    $categoriesInSelect = array_rand($categories, $numberCategoriesInSelect);
    $productCategoriesImploded = '"' . implode('","', $categoriesInSelect) . '"';

    file_put_contents(sprintf('%s/es_request_%s.txt', $esRequestsDirectory, $numberCategoriesInSelect), $body);

    $body = <<<REQUEST
    {"query" : {"constant_score": {"filter": {"terms": { "categories" : [${productCategoriesImploded}]}}}}}
    
REQUEST;

    file_put_contents(sprintf('%s/es_request_%s.txt', $esRequestsDirectory, $numberCategoriesInSelect), $body);
}


