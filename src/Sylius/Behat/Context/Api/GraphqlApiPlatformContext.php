<?php

declare(strict_types=1);

namespace Sylius\Behat\Context\Api;

use Behat\Behat\Context\Context;
use Behat\Gherkin\Node\PyStringNode;
use Behat\Gherkin\Node\TableNode;
use Behat\Mink\Element\DocumentElement;
use PHPUnit\Framework\ExpectationFailedException;
use Sylius\Behat\Client\GraphqlClientInterface;
use Sylius\Behat\Service\SharedStorageInterface;

/**
 * Context for GraphQL.
 */
final class GraphqlApiPlatformContext implements Context
{

    /** @var GraphqlClientInterface */
    private $client;

    /** @var SharedStorageInterface */
    private $sharedStorage;

    public function __construct(GraphqlClientInterface $client,SharedStorageInterface $sharedStorage)
    {
        $this->client = $client;
        $this->sharedStorage = $sharedStorage;
    }


    /**
     * @When I have the following GraphQL request:
     */
    public function IHaveTheFollowingGraphqlRequest(PyStringNode $request)
    {
        $this->graphqlRequest = ['query' => $request->getRaw()];
        $this->graphqlLine = $request->getLine();
    }

    /**
     * @When I send the following GraphQL request:
     */
    public function ISendTheFollowingGraphqlRequest(PyStringNode $request)
    {
        $this->IHaveTheFollowingGraphqlRequest($request);
        $this->sendGraphqlRequest();
    }

    private function saveLastResponse(DocumentElement $response)
    {
        $content = $response->getContent();
        $json = $this->getJsonFromResponse($content);
        if ($json === null) {
            throw new \Exception('Return data is not Json format');
        }
        $this->lastResponse = $json;
    }

    /**
     * @When I should see following response:
     */
    public function IShouldSeeFollowingResponse(PyStringNode $json): bool
    {
        $expected = json_decode($json->getRaw(), true);
        $result_array = self::diff($expected, $this->lastResponse);
        if (empty($result_array)) {
            return true;
        }
        var_dump($result_array);
        var_dump($this->lastResponse);

        throw new \Exception('Expected response doest match last one');
    }

    /**
     * @Then I save value at key :arg1 from last response as :arg2.
     */
    public function iSaveValueAs($key, $valueName)
    {
        $flatResponse = $this->flattenArray($this->lastResponse);
        if (!array_key_exists($key, $flatResponse)) {
            var_dump($flatResponse);

            throw new \Exception(sprintf('Last response did not have any key named %s', $key));
        }
        $this->savedValues[$valueName] = $flatResponse[$key];
    }

    /**
     * @When I send the GraphQL request with variables:
     */
    public function ISendTheGraphqlRequestWithVariables(PyStringNode $variables)
    {
        $this->graphqlRequest['variables'] = $variables->getRaw();
        $this->sendGraphqlRequest();
    }

    /**
     * @When I prepare the variables for GraphQL request with saved data:
     */
    public function IPrepareTheVariablesForGraphqlRequest(PyStringNode $variables)
    {
        $raw = $variables->getRaw();
        preg_match_all('/{(\w+)}/', $raw, $matches);
        $parsed = $raw;
        foreach ($matches[0] as $index => $var_name) {
            $key = $matches[1][$index];
            if (array_key_exists($key, $this->savedValues)) {
                $parsed = str_replace($var_name, $this->savedValues[$key], $parsed);
            }
        }
        $this->graphqlRequest['variables'] = $parsed;
        $this->sendGraphqlRequest();
    }

    /**
     * @When I send the GraphQL request with operationName :operationName
     */
    public function ISendTheGraphqlRequestWithOperation(string $operationName)
    {
        $this->graphqlRequest['operationName'] = $operationName;
        $this->sendGraphqlRequest();
    }

    /**
     * @Then I send the same request again
     * @Then I resend the request
     */
    public function IResendGraphqlRequest(string $method = self::METHOD_POST): DocumentElement
    {
        $response = $this->restContext->iSendARequestTo($method, '/api/v2/graphql?' . http_build_query($this->graphqlRequest));
        $this->saveLastResponse($response);

        return  $response;
    }

    /**
     * @Given I have the following file(s) for a GraphQL request:
     */
    public function iHaveTheFollowingFilesForAGraphqlRequest(TableNode $table)
    {
        $files = [];

        foreach ($table->getHash() as $row) {
            if (!isset($row['name'], $row['file'])) {
                throw new \InvalidArgumentException('You must provide a "name" and "file" column in your table node.');
            }

            $files[$row['name']] = $this->restContext->getMinkParameter('files_path') . \DIRECTORY_SEPARATOR . $row['file'];
        }

        $this->graphqlRequest['files'] = $files;
    }

    /**
     * @Given I have the following GraphQL multipart request map:
     */
    public function iHaveTheFollowingGraphqlMultipartRequestMap(PyStringNode $string)
    {
        $this->graphqlRequest['map'] = $string->getRaw();
    }

    /**
     * @When I send the following GraphQL multipart request operations:
     */
    public function iSendTheFollowingGraphqlMultipartRequestOperations(PyStringNode $string)
    {
        $params = [];
        $params['operations'] = $string->getRaw();
        $params['map'] = $this->graphqlRequest['map'];

        $this->request->setHttpHeader('Content-type', 'multipart/form-data'); // @phpstan-ignore-line
        $this->request->send('POST', '/graphql', $params, $this->graphqlRequest['files']); // @phpstan-ignore-line
    }

    /**
     * @When I send the query to introspect the schema
     */
    public function ISendTheQueryToIntrospectTheSchema()
    {
        $this->graphqlRequest = ['query' => Introspection::getIntrospectionQuery()];
        $this->sendGraphqlRequest();
    }

    /**
     * @And I send this graphql request
     */
    public function ISendThisGraphqlRequest()
    {
        $this->graphqlRequest = ['query' => Introspection::getIntrospectionQuery()];
        $this->sendGraphqlRequest();
    }

    /**
     * @Then the GraphQL field :fieldName is deprecated for the reason :reason
     */
    public function theGraphQLFieldIsDeprecatedForTheReason(string $fieldName, string $reason)
    {
        foreach (json_decode($this->request->getContent(), true)['data']['__type']['fields'] as $field) { // @phpstan-ignore-line
            if ($fieldName === $field['name'] && $field['isDeprecated'] && $reason === $field['deprecationReason']) {
                return;
            }
        }

        throw new ExpectationFailedException(sprintf('The field "%s" is not deprecated.', $fieldName));
    }

    /**
     * @Then I should see following error message :message
     */
    public function iShouldSeeFollowingErrorMessage(string $message): bool
    {
        $flatLastResponse = $this->flattenArray($this->lastResponse);
        if(!key_exists("errors.0.message",$flatLastResponse)){
            var_dump($flatLastResponse);
            throw new \Exception("No errors were produced.");
        }
        if($flatLastResponse["errors.0.message"] !== $message){
            var_dump($flatLastResponse);
            throw new \Exception("The error message is different then expected.");
        }
        return true;
    }

}
