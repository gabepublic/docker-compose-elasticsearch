function createNode(element)
{
  return document.createElement(element);
}

function append(parent, el)
{
  return parent.appendChild(el);
}

const ul = document.getElementById("trucklist");
const food = document.getElementById("food");
//const url = "http://localhost:9200/search?q=";

var query = "";

function onChange(e) {
  this.setState({ query: e.target.value });
}

function handleSearch(e) {
  e.preventDefault();
  fetchResults();
}

function fetchResults {
  console.log(food.value);
  fetch("/search?q=" + food.value)
  .then((resp) => resp.json())
  .then(function(resp){
    let foodtrucks = resp.results;
    return foodtrucks.map(function(author){
      let li = createNode("li"),
      img = createNode("img"),
      span = createNode("span");

      img.src = author.picture.medium;
      span.innerHTML = `&nbsp; ${author.name.first} ${author.name.last}`

      append(li, img);
      append(li, span);
      append(ul, li);
    })
  })
  .catch(function(error){
    console.log(JSON.stringify(error));
  })
}