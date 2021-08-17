@customer_registration
Feature: Account registration
    In order to make future purchases with ease
    As a Visitor
    I need to be able to create an account in the store

    Background:
        Given the store operates on a single channel in "United States"

    @ui @api
    Scenario: Registering a new account with minimum information
        When I want to register a new account
        And I specify the first name as "Saul"
        And I specify the last name as "Goodman"
        And I specify the email as "goodman@gmail.com"
        And I specify the password as "heisenberg"
        And I confirm this password
        And I register this account
        Then I should be notified that new account has been successfully created
        But I should not be logged in

    @ui @api
    Scenario: Registering a new account with minimum information when channel has disabled registration verification
        Given on this channel account verification is not required
        When I want to register a new account
        And I specify the first name as "Saul"
        And I specify the last name as "Goodman"
        And I specify the email as "goodman@gmail.com"
        And I specify the password as "heisenberg"
        And I confirm this password
        And I register this account
        Then I should be notified that new account has been successfully created
        And I should be logged in

    @ui @api
    Scenario: Registering a new account with all details
        When I want to register a new account
        And I specify the first name as "Saul"
        And I specify the last name as "Goodman"
        And I specify the email as "goodman@gmail.com"
        And I specify the password as "heisenberg"
        And I confirm this password
        And I specify the phone number as "123456789"
        And I register this account
        Then I should be notified that new account has been successfully created
        But I should not be logged in

    @ui @api
    Scenario: Registering a guest account
        Given there is a customer "goodman@gmail.com" that placed an order "#001"
        When I want to register a new account
        And I specify the first name as "Saul"
        And I specify the last name as "Goodman"
        And I specify the email as "goodman@gmail.com"
        And I specify the password as "heisenberg"
        And I confirm this password
        And I register this account
        Then I should be notified that new account has been successfully created
        But I should not be logged in


    @graphql
    Scenario: Creating customer account
        When I prepare shop POST customer mutation
        And I supply it with following input
        """
        {
            "firstName": "John",
            "lastName": "Doe",
            "email": "john.doe@example.org",
            "phoneNumber": "+44 123 123 789",
            "subscribedToNewsletter": false,
            "password": "S3cret"
        }
        """
        And I send this graphql request

    @graphql
    Scenario: Creating customer with already existing mail
        When I have the following GraphQL request:
        """
        mutation shop_postCustomer ($input: shop_postCustomerInput!) {
            shop_postCustomer(input: $input){
		        customer{
                    email
                }
            }
        }
        """
        And I prepare the variables for GraphQL request with saved data:
        """
        {
            "input":{
                "firstName": "Jane",
                "lastName": "Doe",
                "email": "jane.doe@example.org",
                "phoneNumber": "+44 123 456 789",
                "subscribedToNewsletter": true,
                "password": "S3cret"
            }
        }
        """
        And I send the same request again
        Then I should see following error message "email: This email is already used."
