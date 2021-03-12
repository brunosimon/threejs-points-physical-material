import StatsJs from 'stats.js'

export default class Stats
{
    constructor()
    {
        this.instance = new StatsJs()
        this.instance.showPanel(3)
        document.body.appendChild(this.instance.dom)
    }

    setRenderPanel(_context)
    {
        this.render = {}
        this.render.context = _context
        this.render.extension = this.render.context.getExtension('EXT_disjoint_timer_query_webgl2')
        this.render.panel = this.instance.addPanel(new StatsJs.Panel('Render (ms)', '#f8f', '#212'))
        this.render.maxValue = 40
    }

    beforeRender()
    {
        // Setup
        this.queryCreated = false
        let queryResultAvailable = false

        // Test if query result available
        if(this.render.query)
        {
            queryResultAvailable = this.render.context.getQueryParameter(this.render.query, this.render.context.QUERY_RESULT_AVAILABLE)

            if(queryResultAvailable)
            {
                const elapsedNanos = this.render.context.getQueryParameter(this.render.query, this.render.context.QUERY_RESULT)
                const panelValue = Math.min(elapsedNanos / 1000 / 1000, this.render.maxValue)
                
                this.render.panel.update(panelValue, this.render.maxValue)
            }
        }

        // If query result available or no query yet
        if(queryResultAvailable || !this.render.query)
        {
            // Create new query
            this.queryCreated = true
            this.render.query = this.render.context.createQuery()
            this.render.context.beginQuery(this.render.extension.TIME_ELAPSED_EXT, this.render.query)
        }

    }

    afterRender()
    {
        // End the query (result will be available "later")
        if(this.queryCreated)
        {
            this.render.context.endQuery(this.render.extension.TIME_ELAPSED_EXT)
        }
    }

    update()
    {
        this.instance.update()
    }
}