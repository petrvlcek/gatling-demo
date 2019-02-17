package io.zonky

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import scala.concurrent.duration._

class DemoSimulation extends Simulation {

  val httpProtocol = http
    .baseUrl("http://latenight.works") // Here is the root for all relative URLs
    .acceptHeader("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8") // Here are the common headers
    .acceptEncodingHeader("gzip, deflate")
    .acceptLanguageHeader("en-US,en;q=0.5")
    .userAgentHeader("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:16.0) Gecko/20100101 Firefox/16.0")

  val scn = scenario("First scenario")
    .exec(http("Get homepage")
      .get("/"))
    .pause(4 seconds, 10 seconds)
    .exec(http("Get homepage")
      .get("/"))

  setUp(scn.inject(atOnceUsers(1)).protocols(httpProtocol))
}