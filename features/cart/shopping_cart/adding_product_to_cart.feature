@shopping_cart
Feature: Adding a simple product to the cart
    In order to select products for purchase
    As a Visitor
    I want to be able to add simple products to cart

    Background:
        Given the store operates on a single channel in "United States"

    @ui @api
    Scenario: Adding a simple product to the cart
        Given the store has a product "T-shirt banana" priced at "$12.54"
        When I add this product to the cart
        Then I should be on my cart summary page
        And I should be notified that the product has been successfully added
        And there should be one item in my cart
        And this item should have name "T-shirt banana"

    @ui @api
    Scenario: Adding a product to the cart as a logged in customer
        Given I am a logged in customer
        And the store has a product "Oathkeeper" priced at "$99.99"
        When I add this product to the cart
        Then I should be on my cart summary page
        And I should be notified that the product has been successfully added
        And there should be one item in my cart
        And this item should have name "Oathkeeper"

    @api
    Scenario: Preventing adding to cart item with 0 quantity
        Given the store has a product "T-shirt banana" priced at "$12.54"
        When I try to add 0 products "T-shirt banana" to the cart
        Then I should be notified that quantity of added product cannot be lower that 1
        And there should be 0 item in my cart

    @graphql
    Scenario: Adding a simple product to the cart
        Given the store has a product "T-shirt banana" priced at "$12.50"
        When I send the following GraphQL request:
        """
        query getProductDetails {
            product(id: "/api/v2/shop/products/T_SHIRT_BANANA") {
                id
                variants{
                    collection{
                        id
                        name
                    }
                }
            }
        }
        """
        Then I should see following response:
        """
        {
            "data": {
                "product": {
                    "id": "/api/v2/shop/products/T_SHIRT_BANANA",
                    "variants": {
                        "collection": [
                            {
                                "id": "/api/v2/shop/product-variants/T_SHIRT_BANANA",
                                "name": "T-shirt banana"
                            }
                        ]
                    }
                }
            }
        }
        """
        When I send the following GraphQL request:
        """
        mutation createCart {
            shop_postOrder(input: {localeCode: "en_US"}) {
                order {
                    tokenValue
                }
            }
        }
        """
        Then I save value at key "order.tokenValue" from last response as "orderId".
        When I have the following GraphQL request:
        """
        mutation addItemToCart ($input: shop_add_itemOrderInput!) {
            shop_add_itemOrder(input: $input) {
                order{ total }
            }
        }
        """
        And I prepare the variables for GraphQL request with saved data:
        """
        {
            "input": {
                "id": "/api/v2/shop/orders/{orderId}",
                "productVariant": "/api/v2/shop/product-variants/T_SHIRT_BANANA",
                "quantity": 2
          }
        }
        """
        Then I have the following GraphQL request:
        """
        query pullCart($orderId: ID!) {
            order(id: $orderId) {
                items {
                    edges{
                        node{
                            productName
                            _id
                            quantity
                            unitPrice
                        }
                    }
                }
            }
        }
        """
        And I prepare the variables for GraphQL request with saved data:
        """
        {
            "orderId": "/api/v2/shop/orders/{orderId}"
        }
        """
        Then I save value at key "items.edges.0.node._id" from last response as "orderItemId".
    #TODO: order item id should always be the same as DB should be purged
#        Then I should see following response:
#        """
#        {
#          "data": {
#            "order": {
#              "items": {
#                "edges": [
#                  {
#                    "node": {
#                      "productName": "T-shirt banana",
#                      "quantity": 2,
#                      "unitPrice": 1250
#                    }
#                  }
#                ]
#              }
#            }
#          }
#        }
#        """
        Then I have the following GraphQL request:
        """
         mutation removeItemFromCart ($removeItemOrderInput: shop_remove_itemOrderInput!) {
            shop_remove_itemOrder(input:$removeItemOrderInput) {
             order {
               items {
                 edges {
                   node {
                     id
                   }
                 }
               }
             }
           }
         }
        """
        And I prepare the variables for GraphQL request with saved data:
        """
        {
            "removeItemOrderInput":  {
                "id": "/api/v2/shop/orders/{orderId}",
                "orderItemId": "{orderItemId}"
            }
        }
        """
        Then I have the following GraphQL request:
        """
        query pullCart($orderId: ID!) {
            order(id: $orderId) {
                items {
                    edges{
                        node{
                            productName
                            id
                            quantity
                            unitPrice
                        }
                    }
                }
            }
        }
        """
        And I prepare the variables for GraphQL request with saved data:
        """
        {
            "orderId": "/api/v2/shop/orders/{orderId}"
        }
        """
        Then I should see following response:
        """
        {
            "data": {
                "order": {
                    "items": {
                        "edges": []
                    }
                }
            }
        }
        """
