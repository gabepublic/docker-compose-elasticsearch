
var query = "burger";

const food = document.getElementById("query");
const ul = document.getElementById("trucklist");

function handleSearch() {
  console.log("Fetching query: ", query);
  while (ul.firstChild) {
        ul.removeChild(ul.firstChild);
    }
  fetchResults();
}

function updateQuery() {
  query = food.value;
  console.log("Update query: ", query);
}

function createNode(element)
{
  return document.createElement(element);
}

function append(parent, el)
{
  return parent.appendChild(el);
}

function fetchResults() {
  fetch("/search?q=" + query)
  .then((resp) => resp.json())
  .then(function(resp){
    //console.log("trucks: ");
    //console.log(resp);
    let trucks = resp.trucks;
    return trucks.map(function(truck){
      //console.log("truck: ");
      //console.log(truck);
      let li = createNode("li");
      let span1 = createNode("span");
      //console.log("truck name: ", truck.name);
      span1.innerHTML = `&nbsp; ${truck.name}; &nbsp;`
      let span2 = createNode("span");
      span2.innerHTML = `&nbsp; Drinks: ${truck.drinks}; &nbsp;`
      let span3 = createNode("span");
      let span4 = createNode("span");
      append(li, span1);
      append(li, span2);
      append(li, span3);
      append(li, span4);
      append(ul, li);
      let fooditems = truck.fooditems;
      //console.log("food items: ");
      //console.log(fooditems);
      fooditems.map(function(fi){
        //console.log("FI: ");
        //console.log(fi);
        let span31 = createNode("span");
        span31.innerHTML = `&nbsp; ${fi}; &nbsp;`;
        append(span3, span31);
      })
      let branches = truck.branches;
      return branches.map(function(branch){
        //console.log("branch: ");
        //console.log(branch);        
        let span41 = createNode("span");
        span41.innerHTML = `&nbsp; ${branch.address}; &nbsp;`;
        append(span4, span41);
      })
    })
  })
  .catch(function(error){
    console.log(JSON.stringify(error));
  })
}