class PuzzleGame
  constructor: ->
    @puzzleCanvas = document.getElementById('puzzleCanvas')
    @referenceCanvas = document.getElementById('referenceCanvas')
    @ctx = @puzzleCanvas.getContext('2d')
    @referenceCtx = @referenceCanvas.getContext('2d')
    @pieces = []
    @selectedPiece = null
    @isDragging = false
    @image = null
    @pieceCount = 100
    @tabSize = 20
    @initializeControls()

  initializeControls: ->
    imageInput = document.getElementById('imageInput')
    imageInput.addEventListener 'change', (e) =>
      file = e.target.files[0]
      reader = new FileReader()
      reader.onload = (event) =>
        img = new Image()
        img.onload = =>
          @image = img
          @setupCanvases()
        img.src = event.target.result
      reader.readAsDataURL(file)

    # 拼圖片數控制
    rangeInput = document.getElementById('pieceRange')
    pieceCount = document.getElementById('pieceCount')
    rangeInput.addEventListener 'input', (e) =>
      @pieceCount = parseInt(e.target.value)
      pieceCount.textContent = @pieceCount

    # 開始遊戲按鈕
    startButton = document.getElementById('startGame')
    startButton.addEventListener 'click', => @startGame()

  setupCanvases: ->
    # 設置參考圖
    refSize = 200
    ratio = @image.width / @image.height
    if ratio > 1
      @referenceCanvas.width = refSize
      @referenceCanvas.height = refSize / ratio
    else
      @referenceCanvas.width = refSize * ratio
      @referenceCanvas.height = refSize
    
    # 繪製參考圖
    @referenceCtx.drawImage(@image, 0, 0, @referenceCanvas.width, @referenceCanvas.height)

    # 設置主拼圖區域（較大的工作區域）
    @puzzleCanvas.width = 1000
    @puzzleCanvas.height = 800

    # 計算實際拼圖大小（在畫布中央）
    if ratio > 1
      @puzzleWidth = Math.min(600, @puzzleCanvas.width * 0.6)
      @puzzleHeight = @puzzleWidth / ratio
    else
      @puzzleHeight = Math.min(500, @puzzleCanvas.height * 0.6)
      @puzzleWidth = @puzzleHeight * ratio

    # 計算拼圖在畫布中的起始位置
    @puzzleX = (@puzzleCanvas.width - @puzzleWidth) / 2
    @puzzleY = (@puzzleCanvas.height - @puzzleHeight) / 2

    # 繪製拼圖區域指示框
    @ctx.strokeStyle = '#ccc'
    @ctx.strokeRect(@puzzleX, @puzzleY, @puzzleWidth, @puzzleHeight)

  startGame: ->
    return unless @image
    @setupCanvases()
    
    # 計算拼圖片的行列數
    @rows = Math.floor(Math.sqrt(@pieceCount * (@puzzleCanvas.height / @puzzleCanvas.width)))
    @cols = Math.floor(@pieceCount / @rows)
    
    # 設置適當的突起大小
    @tabSize = Math.min(@puzzleCanvas.width / (@cols * 4), @puzzleCanvas.height / (@rows * 4))
    
    @createPieces()
    @shufflePieces()
    @draw()
    @addEventListeners()

  createPieces: ->
    @pieces = []
    pieceWidth = @puzzleWidth / @cols
    pieceHeight = @puzzleHeight / @rows
    
    for row in [0...@rows]
      for col in [0...@cols]
        tabs = @calculateTabs(row, col)
        piece =
          x: col * pieceWidth + @puzzleX
          y: row * pieceHeight + @puzzleY
          width: pieceWidth
          height: pieceHeight
          correctX: col * pieceWidth + @puzzleX
          correctY: row * pieceHeight + @puzzleY
          row: row
          col: col
          tabs: tabs
        @pieces.push(piece)

  calculateTabs: (row, col) ->
    # 計算每個邊的凸起或凹陷
    top: if row == 0 then null else (Math.random() < 0.5)
    right: if col == @cols - 1 then null else (Math.random() < 0.5)
    bottom: if row == @rows - 1 then null else (Math.random() < 0.5)
    left: if col == 0 then null else @pieces[@pieces.length - 1]?.tabs.right ? null

  shufflePieces: ->
    # 將拼圖片隨機放置在畫布範圍內，但避免太靠近邊緣
    margin = 50  # 邊緣留空間
    for piece in @pieces
      piece.x = margin + Math.random() * (@puzzleCanvas.width - piece.width - margin * 2)
      piece.y = margin + Math.random() * (@puzzleCanvas.height - piece.height - margin * 2)
      piece.isPlaced = false

  draw: ->
    # 清除畫布
    @ctx.clearRect(0, 0, @puzzleCanvas.width, @puzzleCanvas.height)
    
    # 繪製目標區域框
    @ctx.strokeStyle = '#ccc'
    @ctx.strokeRect(@puzzleX, @puzzleY, @puzzleWidth, @puzzleHeight)
    
    # 繪製所有拼圖片
    for piece in @pieces
      @drawPieceOnCanvas(piece, @ctx)

  drawPieceOnCanvas: (piece, ctx) ->
    ctx.beginPath()
    
    # 開始繪製路徑
    ctx.moveTo(piece.x, piece.y)
    
    # 上邊
    if piece.tabs.top == null
      ctx.lineTo(piece.x + piece.width, piece.y)
    else
      ctx.lineTo(piece.x + piece.width/3, piece.y)
      if piece.tabs.top
        ctx.bezierCurveTo(
          piece.x + piece.width/3, piece.y - @tabSize,
          piece.x + piece.width*2/3, piece.y - @tabSize,
          piece.x + piece.width*2/3, piece.y
        )
      else
        ctx.bezierCurveTo(
          piece.x + piece.width/3, piece.y + @tabSize,
          piece.x + piece.width*2/3, piece.y + @tabSize,
          piece.x + piece.width*2/3, piece.y
        )
      ctx.lineTo(piece.x + piece.width, piece.y)
    
    # 右邊
    if piece.tabs.right == null
      ctx.lineTo(piece.x + piece.width, piece.y + piece.height)
    else
      ctx.lineTo(piece.x + piece.width, piece.y + piece.height/3)
      if piece.tabs.right
        ctx.bezierCurveTo(
          piece.x + piece.width + @tabSize, piece.y + piece.height/3,
          piece.x + piece.width + @tabSize, piece.y + piece.height*2/3,
          piece.x + piece.width, piece.y + piece.height*2/3
        )
      else
        ctx.bezierCurveTo(
          piece.x + piece.width - @tabSize, piece.y + piece.height/3,
          piece.x + piece.width - @tabSize, piece.y + piece.height*2/3,
          piece.x + piece.width, piece.y + piece.height*2/3
        )
      ctx.lineTo(piece.x + piece.width, piece.y + piece.height)
    
    # 下邊
    if piece.tabs.bottom == null
      ctx.lineTo(piece.x, piece.y + piece.height)
    else
      ctx.lineTo(piece.x + piece.width*2/3, piece.y + piece.height)
      if piece.tabs.bottom
        ctx.bezierCurveTo(
          piece.x + piece.width*2/3, piece.y + piece.height + @tabSize,
          piece.x + piece.width/3, piece.y + piece.height + @tabSize,
          piece.x + piece.width/3, piece.y + piece.height
        )
      else
        ctx.bezierCurveTo(
          piece.x + piece.width*2/3, piece.y + piece.height - @tabSize,
          piece.x + piece.width/3, piece.y + piece.height - @tabSize,
          piece.x + piece.width/3, piece.y + piece.height
        )
      ctx.lineTo(piece.x, piece.y + piece.height)
    
    # 左邊
    if piece.tabs.left == null
      ctx.lineTo(piece.x, piece.y)
    else
      ctx.lineTo(piece.x, piece.y + piece.height*2/3)
      if piece.tabs.left
        ctx.bezierCurveTo(
          piece.x + @tabSize, piece.y + piece.height*2/3,
          piece.x + @tabSize, piece.y + piece.height/3,
          piece.x, piece.y + piece.height/3
        )
      else
        ctx.bezierCurveTo(
          piece.x - @tabSize, piece.y + piece.height*2/3,
          piece.x - @tabSize, piece.y + piece.height/3,
          piece.x, piece.y + piece.height/3
        )
      ctx.lineTo(piece.x, piece.y)
    
    ctx.closePath()
    
    # 修改圖片繪製部分
    ctx.save()
    ctx.clip()
    ctx.drawImage(
      @image,
      (piece.correctX - @puzzleX) * (@image.width / @puzzleWidth),
      (piece.correctY - @puzzleY) * (@image.height / @puzzleHeight),
      piece.width * (@image.width / @puzzleWidth),
      piece.height * (@image.height / @puzzleHeight),
      piece.x, piece.y,
      piece.width, piece.height
    )
    ctx.restore()
    
    # 繪製邊框
    ctx.strokeStyle = '#333'
    ctx.lineWidth = 2
    ctx.stroke()

  addEventListeners: ->
    @puzzleCanvas.addEventListener 'mousedown', (e) => @onMouseDown(e)
    @puzzleCanvas.addEventListener 'mousemove', (e) => @onMouseMove(e)
    @puzzleCanvas.addEventListener 'mouseup', (e) => @onMouseUp(e)

  onMouseDown: (e) ->
    rect = @puzzleCanvas.getBoundingClientRect()
    x = e.clientX - rect.left
    y = e.clientY - rect.top
    
    for piece in @pieces
      if x >= piece.x && x <= piece.x + piece.width &&
         y >= piece.y && y <= piece.y + piece.height
        @selectedPiece = piece
        @isDragging = true
        @dragOffsetX = x - piece.x
        @dragOffsetY = y - piece.y
        break

  onMouseMove: (e) ->
    if @isDragging && @selectedPiece
      rect = @puzzleCanvas.getBoundingClientRect()
      x = e.clientX - rect.left
      y = e.clientY - rect.top
      
      # 限制拼圖片在拼圖區域內
      x = Math.max(0, Math.min(x, @puzzleCanvas.width))
      y = Math.max(0, Math.min(y, @puzzleCanvas.height))
      
      @selectedPiece.x = x - @dragOffsetX
      @selectedPiece.y = y - @dragOffsetY
      @draw()

  onMouseUp: (e) ->
    if @selectedPiece
      # 檢查是否接近正確位置
      if Math.abs(@selectedPiece.x - @selectedPiece.correctX) < 20 &&
         Math.abs(@selectedPiece.y - @selectedPiece.correctY) < 20
        @selectedPiece.x = @selectedPiece.correctX
        @selectedPiece.y = @selectedPiece.correctY
        @selectedPiece.isPlaced = true  # 標記為已放置
      
      @draw()
      @checkCompletion()
    
    @isDragging = false
    @selectedPiece = null

  checkCompletion: ->
    completed = @pieces.every (piece) ->
      piece.x == piece.correctX && piece.y == piece.correctY
    
    if completed
      document.getElementById('completion-message').style.display = 'block'
      setTimeout ->
        document.getElementById('completion-message').style.display = 'none'
      , 3000

# 初始化遊戲
game = new PuzzleGame() 