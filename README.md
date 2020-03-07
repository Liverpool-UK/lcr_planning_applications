This is a scraper that runs on [Morph](https://morph.io). To get started [see the documentation](https://morph.io/documentation)

## Environment Variables

The code expects (up to) two envirvonment variables to be set to run properly:

 * `MORPH_DAYS` How far back to look for new planning applications
 * `MORPH_POSTCODE_GEOCODE_COUNT` How many new postcodes it should attempt to geocode each time the scraper runs.  This is used to populate the `neighbourhood_latitude` and `neighbourhood_longitude` columns in the database, which provide a *rough* location of the planning application.  You should aim to make the number higher than the number of new applications each day, but not too high so you aren't hammering the [postcodes.io](https://postcodes.io) API.  A few hundred seems a sensible option.

## Tools

  * To geocode the planning application locations we need to find the postcode.  `rake find_postcodes db=name-of-your-planning-apps-database | sort | uniq`
