@applying_promotion_coupon
Feature: Applying promotion coupon
    In order to pay proper amount after using the promotion coupon
    As a Visitor
    I want to have promotion coupon's discounts applied to my cart

    Background:
        Given the store operates on a single channel in "United States"
        And the store has a product "PHP T-Shirt" priced at "$100.00"
        And the store has promotion "Christmas sale" with coupon "SANTA2016"
        And this promotion gives "$10.00" discount to every order

    @ui @api
    Scenario: Receiving fixed discount for my cart
        When I add product "PHP T-Shirt" to the cart
        And I use coupon with code "SANTA2016"
        Then my cart total should be "$90.00"
        And my discount should be "-$10.00"

    @graphql
    Scenario: Adding and removing simple discount promotion coupon
        Given this promotion gives "$10.00" discount to every order
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
                "productVariant": "/api/v2/shop/product-variants/PHP_T_SHIRT",
                "quantity": 2
          }
        }
        """
        Then I have the following GraphQL request:
        """
        mutation applyCoupon ($applyCouponInput: shop_apply_couponOrderInput!) {
            shop_apply_couponOrder(input:$applyCouponInput){
                order{
                    total
                }
            }
        }
        """
        And I prepare the variables for GraphQL request with saved data:
        """
        {
            "applyCouponInput": {
                "orderTokenValue": "{orderId}",
                "couponCode":  "SANTA2016"
            }
        }
        """
        Then I should see following response:
        """
        {
            "data": {
                "shop_apply_couponOrder": {
                    "order": {
                        "total": 19000
                    }
                }
            }
        }
        """
