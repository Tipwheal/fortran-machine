module jade
  use string_helpers

  implicit none

  contains

  subroutine jadefile(templatefile)
    character(len=*)  :: templatefile
    character(len=80)  :: spaceless, tag, closeTag, className, elemID
    character(len=200) :: inputLine, outputLine, innerContent
    integer            :: templater, io, spaceCount, unitNo, lastSpaceCount, lastIndent
    character(len=3)   :: AFORMAT = '(a)'
    integer, dimension (0:30) :: spaceLevels
    character(len=80), dimension (0:30) :: tagLevels

    open(newunit=templater, file=templatefile)
    templatefile = ''
    lastSpaceCount = -1
    lastIndent = 0
    do
      read(templater, '(A)', IOSTAT=io) inputLine
      if (io < 0) exit

      spaceless = trim(inputLine)
      call compact(spaceless)
      spaceless = trim(spaceless) // '   '
      spaceCount = index(inputLine, trim(spaceless))
      className = ''
      elemID = ''
      innerContent = spaceless(index(spaceless, ' ') + 1:)

      if (spaceless(1:1) == '.') then
        ! starts with a class definition
        tag = 'div'
        className = spaceless(2: index(spaceless, ' ') - 1)
        if (index(className, '#') > 0) then
          className = className(1 : index(className, '#') - 1)
          elemID = spaceless(index(spaceless, '#') : index(spaceless, ' '))
        endif
      else
        ! starts with an ID definition
        if (spaceless(1:1) == '#') then
          tag = 'div'
          elemID = spaceless(2: index(spaceless, ' ') - 1)
          if (index(elemID, '.') > 0) then
            elemID = elemID(1 : index(elemID, '.') - 1)
            className = spaceless(index(spaceless, '.') : index(spaceless, ' '))
          endif
        else
          if (spaceless(1:1) == '(') then
            ! starts with a div attributes
            tag = 'div' // spaceless(1: index(spaceless, ' ') - 1)
          else
            ! custom tag
            tag = spaceless(1: index(spaceless, ' ') - 1)
            if (index(tag, '.') > 0 .and. index(tag, '.') < index(tag, '(')) then
              tag = tag(1: index(tag, '.') - 1)
              className = spaceless(index(spaceless, '.') : index(spaceless, ' '))
            endif
            if (index(tag, '#') > 0 .and. index(tag, '#') < index(tag, '(')) then
              tag = tag(1: index(tag, '#') - 1)
              elemID = elemID(index(spaceless, '#') : index(spaceless, ' '))
            endif
          endif
        endif
      endif

      ! handle multiple classes
      call string_replace(className, '.', ' ')
      ! just make sure I don't have a # in the ID
      call string_replace(elemID, '#', '')

      if (index(tag, '(') > 0) then
        ! todo: substitute values, handle multiple attributes
        call string_replace(tag, '(', ' ')
        call string_replace(tag, ')', ' ')
      endif

      outputLine = '<' // &
        trim(tag) // &
        ' id="' // trim(elemID) // '"' // &
        ' class="' // trim(className) // '"'

      !if (index(tag, 'img') == 1 .or. index(tag, 'link') == 1) then
        ! single closing tag
      !  outputLine = trim(outputLine) // &
      !    '/>'
      !else
        ! complete opening tag and inner content
      outputLine = trim(outputLine) // &
        '>' // &
        trim(innerContent)

      !endif

      ! determine close tag, ahead of time
      closeTag = tag
      if (index(closeTag, '(') > 0) then
        closeTag = closeTag(1 : index(closeTag, '(') - 1)
      endif

      if (lastSpaceCount < spaceCount) then
        ! went up a level
        lastIndent = lastIndent + 1
        spaceLevels(lastIndent) = spaceCount
        tagLevels(lastIndent) = closeTag
      else
        if (lastSpaceCount == spaceCount) then
          ! same level; previous tag is closed; replace with this tag
          outputLine = trim(outputLine) // &
            '</' // &
            trim(tagLevels(lastIndent)) // &
            '>'
          tagLevels(lastIndent) = closeTag
        else
          ! went down at least one level
          do
            if (spaceLevels(lastIndent) >= spaceCount) then
              ! closed or sibling tag
              outputLine = trim(outputLine) // &
                '</' // &
                trim(tagLevels(lastIndent)) // &
                '>'
              lastIndent = lastIndent - 1
            else
              ! bottomed out; open this tag
              tagLevels(lastIndent) = closeTag
              exit
            endif
          end do
        endif
      endif
      lastSpaceCount = spaceCount

      templatefile = trim(templatefile) // outputLine
    end do
    close(templater)
  endsubroutine
endmodule
